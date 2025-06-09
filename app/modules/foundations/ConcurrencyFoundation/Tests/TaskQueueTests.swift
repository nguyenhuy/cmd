// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppKit
import Combine
import ConcurrencyFoundation
import SwiftTesting
import Testing

struct TaskQueueTests {

  @Test("Executes a single task")
  func test_singleTask() async throws {
    let queue = TaskQueue<Int, Never>()
    let completion = expectation(description: "Task completed")
    var results = [Int]()

    let cancellable = queue.sink { value in
      results.append(value)
      completion.fulfill()
    }
    defer { cancellable.cancel() }

    queue.queue { 42 }

    try await fulfillment(of: [completion])
    #expect(results == [42])
  }

  @Test("Tasks execute in FIFO order")
  func test_fifoOrder() async throws {
    let queue = TaskQueue<Int, Never>()
    let completion = expectation(description: "All tasks completed")
    var results = [Int]()

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 3 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    queue.queue { 1 }
    queue.queue { 2 }
    queue.queue { 3 }

    try await fulfillment(of: [completion])
    #expect(results == [1, 2, 3], "Tasks should execute in FIFO order")
  }

  @Test("All tasks execute even when queued while another is running")
  func test_allTasksExecute() async throws {
    let queue = TaskQueue<Int, Never>()
    let firstTaskStarted = expectation(description: "First task started")
    let firstTaskReady = expectation(description: "First task ready to complete")
    let allTasksCompleted = expectation(description: "All tasks completed")
    var results = [Int]()

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 3 {
        allTasksCompleted.fulfill()
      }
    }
    defer { cancellable.cancel() }

    // Queue a task that we can control completion of
    queue.queue {
      firstTaskStarted.fulfill()
      do {
        try await fulfillment(of: [firstTaskReady])
      } catch {
        Issue.record(error)
      }
      return 1
    }

    // Wait for first task to start
    try await fulfillment(of: [firstTaskStarted])

    // Queue more tasks while first is running
    queue.queue { 2 }
    queue.queue { 3 }

    // Allow first task to complete
    firstTaskReady.fulfill()

    try await fulfillment(of: [allTasksCompleted])
    #expect(results == [1, 2, 3], "All tasks should execute in order of queueing")
  }

  @Test("Tasks execute sequentially")
  func test_sequentialExecution() async throws {
    let queue = TaskQueue<Int, Never>()
    let completion = expectation(description: "All tasks completed")
    var results = [Int]()
    let executionOrder = Atomic<[Int]>([])

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 2 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    queue.queue {
      executionOrder.mutate { $0.append(1) }
      return 1
    }

    queue.queue {
      executionOrder.mutate { $0.append(2) }
      return 2
    }

    try await fulfillment(of: [completion])
    #expect(executionOrder.value == [1, 2], "Tasks should execute in order")
    #expect(results == [1, 2], "Results should be in order")
  }

  @Test("Task with delay does not block queue processing")
  func test_taskWithDelay() async throws {
    let queue = TaskQueue<Int, Never>()
    let completion = expectation(description: "All tasks completed")
    var results = [Int]()

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 3 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    queue.queue {
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
      return 1
    }

    queue.queue {
      try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
      return 2
    }

    queue.queue {
      3
    }

    try await fulfillment(of: [completion], timeout: 10) // Large timeout as Task.sleep is not accurate.
    #expect(results == [1, 2, 3], "Tasks should complete in order despite different execution times")
  }

  @Test("Queue processes tasks after failure")
  func test_continuesAfterTaskFailure() async throws {
    let queue = TaskQueue<Int, any Error>()
    let completion = expectation(description: "Successful task completed")
    var results = [Int]()

    let cancellable = queue.sink(
      receiveCompletion: { completion in
        switch completion {
        case .finished:
          break
        case .failure(let error):
          Issue.record("Received error: \(error)")
        }
      },
      receiveValue: { value in
        results.append(value)
        completion.fulfill()
      })
    defer { cancellable.cancel() }

    // First task throws an error
    queue.queue {
      throw NSError(domain: "test", code: 1)
    }

    // Second task should still execute
    queue.queue {
      42
    }

    try await fulfillment(of: [completion])
    #expect(results == [42], "Second task should execute after first task fails")
  }

  // MARK: - Awaitable Tests

  @Test("Returns result when awaiting non-throwing task")
  func test_awaitableNonThrowingTask() async {
    let queue = TaskQueue<Int, Never>()

    let result = await queue.queueAndAwait {
      42
    }

    #expect(result == 42, "Awaiting queue should return the task result")
  }

  @Test("Returns result when awaiting throwing task")
  func test_awaitableThrowingTask() async throws {
    let queue = TaskQueue<Int, Never>()

    let result = await queue.queueAndAwait {
      42
    }

    #expect(result == 42, "Awaiting queue should return the task result")
  }

  @Test("Throws error when awaiting failing task")
  func test_awaitableThrowingTaskFailure() async {
    let queue = TaskQueue<Int, any Error>()
    let testError = NSError(domain: "test", code: 1)

    do {
      _ = try await queue.queueAndAwait {
        throw testError
      }
      Issue.record("Should have thrown an error")
    } catch {
      #expect((error as NSError).domain == testError.domain, "Should throw the original error")
      #expect((error as NSError).code == testError.code, "Should throw the original error with same code")
    }
  }

  @Test("Multiple awaitable tasks execute in order")
  func test_multipleAwaitableTasks() async {
    let queue = TaskQueue<Int, Never>()
    let executionOrder = Atomic<[Int]>([])

    // Start all tasks concurrently
    let result1 = queue.queue {
      executionOrder.mutate { $0.append(1) }
      return 1
    }

    let result2 = queue.queue {
      executionOrder.mutate { $0.append(2) }
      return 2
    }

    let result3 = queue.queue {
      executionOrder.mutate { $0.append(3) }
      return 3
    }

    // Wait for all tasks to complete
    let results = await [result1.value, result2.value, result3.value]

    #expect(results == [1, 2, 3], "Results should be returned in order")
    #expect(executionOrder.value == [1, 2, 3], "Tasks should execute in the order they were queued")
  }

  @Test("Awaiting tasks with delay return in order")
  func test_awaitableTasksWithDelay() async throws {
    let queue = TaskQueue<Int, Never>()

    async let result1 = queue.queueAndAwait {
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
      return 1
    }

    async let result2 = queue.queueAndAwait {
      try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
      return 2
    }

    async let result3 = queue.queueAndAwait {
      3
    }

    // Wait for all tasks to complete
    let results = await [result1, result2, result3]

    #expect(results == [1, 2, 3], "Results should be returned in the order tasks were queued despite different execution times")
  }

  @Test("Results returned match published values")
  func test_resultsMatchPublishedValues() async throws {
    let queue = TaskQueue<Int, Never>()
    let completion = expectation(description: "All tasks published")
    let publishedResults = Atomic<[Int]>([])

    let cancellable = queue.sink { value in
      publishedResults.mutate { $0.append(value) }
      if publishedResults.value.count == 3 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    let result1 = queue.queue {
      1
    }
    let result2 = queue.queue {
      2
    }
    let result3 = queue.queue {
      3
    }

    let awaitedResults = await [result1.value, result2.value, result3.value]
    try await fulfillment(of: [completion])

    #expect(awaitedResults == publishedResults.value, "Awaited results should match published values")
  }
}
