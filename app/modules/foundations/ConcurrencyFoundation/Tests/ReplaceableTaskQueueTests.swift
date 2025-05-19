// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Combine
import ConcurrencyFoundation
import SwiftTesting
import Testing

struct ReplaceableTaskQueueTests {

  @Test("Executes a single task")
  func test_singleTask() async throws {
    let queue = ReplaceableTaskQueue<Int>()
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

  @Test("Currently running task completes even when new task is queued")
  func test_runningTaskCompletes() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let firstTaskStarted = expectation(description: "First task started")
    let firstTaskReady = expectation(description: "First task ready to complete")
    let firstTaskCompleted = expectation(description: "First task completed")
    let secondTaskCompleted = expectation(description: "Second task completed")
    var results: [Int] = []

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 1 {
        firstTaskCompleted.fulfill()
      } else if results.count == 2 {
        secondTaskCompleted.fulfill()
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

    // Queue another task while first is running
    queue.queue { 2 }

    // Allow first task to complete
    firstTaskReady.fulfill()

    try await fulfillment(of: [firstTaskCompleted, secondTaskCompleted])
    #expect(results == [1, 2])
  }

  @Test("New task replaces pending task")
  func test_replacePendingTask() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let firstTaskStarted = expectation(description: "First task started")
    let firstTaskReady = expectation(description: "First task ready to complete")
    let completion = expectation(description: "All tasks completed")
    var results: [Int] = []

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 2 {
        completion.fulfill()
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

    try await fulfillment(of: [firstTaskStarted])

    // Queue two tasks while first is running - the second should replace the first
    queue.queue { 2 } // This should be replaced
    queue.queue { 3 } // This should run after task 1

    // Allow first task to complete
    firstTaskReady.fulfill()

    try await fulfillment(of: [completion])
    #expect(results == [1, 3], "Should receive results from first and third task only")
  }

  @Test("Tasks execute sequentially")
  func test_sequentialExecution() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let firstTaskStarted = expectation(description: "First task started")
    let secondTaskStarted = expectation(description: "Second task started")
    let completion = expectation(description: "All tasks completed")
    var results: [Int] = []
    let executionOrder = Atomic<[Int]>([])

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 2 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    queue.queue {
      firstTaskStarted.fulfill()
      executionOrder.mutate { $0.append(1) }
      return 1
    }

    queue.queue {
      secondTaskStarted.fulfill()
      executionOrder.mutate { $0.append(2) }
      return 2
    }

    try await fulfillment(of: [firstTaskStarted, secondTaskStarted, completion])
    #expect(executionOrder.value == [1, 2], "Tasks should execute in order")
    #expect(results == [1, 2], "Results should be in order")
  }

  @Test("Continues processing after task failure")
  func test_continuesAfterTaskFailure() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let completion = expectation(description: "Successful task completed")
    var results: [Int] = []

    let cancellable = queue.sink { value in
      results.append(value)
      completion.fulfill()
    }
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

  @Test("Handles failure in the middle of multiple tasks")
  func test_handlesMiddleTaskFailure() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let completion = expectation(description: "All tasks completed")
    var results: [Int] = []

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 2 {
        completion.fulfill()
      }
    }
    defer { cancellable.cancel() }

    // First task succeeds
    queue.queue { 1 }

    // Second task fails
    queue.queue {
      throw NSError(domain: "test", code: 1)
    }

    // Third task should still execute
    queue.queue { 3 }

    try await fulfillment(of: [completion])
    #expect(results == [1, 3], "First and third tasks should execute successfully")
  }

  @Test("Replace task behavior works after failure")
  func test_replaceTaskAfterFailure() async throws {
    let queue = ReplaceableTaskQueue<Int>()
    let firstTaskStarted = expectation(description: "First task started")
    let firstTaskReady = expectation(description: "First task ready to complete")
    let completion = expectation(description: "All tasks completed")
    var results: [Int] = []

    let cancellable = queue.sink { value in
      results.append(value)
      if results.count == 1 {
        completion.fulfill()
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
      throw NSError(domain: "test", code: 1)
    }

    try await fulfillment(of: [firstTaskStarted])

    // Queue two tasks while first is running
    queue.queue { 2 } // This should be replaced
    queue.queue { 3 } // This should run after the failing task

    // Allow first task to complete (with failure)
    firstTaskReady.fulfill()

    try await fulfillment(of: [completion])
    #expect(results == [3], "Only the replacing task should execute after failure")
  }
}
