// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Combine
import SwiftTesting
import Testing
@testable import ConcurrencyFoundation

// MARK: - CurrentValueStreamTests

struct CurrentValueStreamTests {
  @Test("CurrentValueStream maintains current value and broadcasts updates")
  func test_currentValueAndUpdates() async throws {
    let subject = CurrentValueSubject<Int, Never>(0)
    let stream = CurrentValueStream(value: subject)

    #expect(stream.value == 0)

    let valuesReceived = expectation(description: "Values received")
    var receivedValues = [Int]()

    Task {
      for await value in stream {
        receivedValues.append(value)
        if receivedValues.count == 3 {
          valuesReceived.fulfill()
        }
      }
    }

    subject.send(1)
    subject.send(2)

    try await fulfillment(of: [valuesReceived])
    #expect(receivedValues == [0, 1, 2])
    #expect(stream.value == 2)
  }

  @Test("CurrentValueStream supports multiple subscribers")
  func test_multipleSubscribers() async throws {
    let (stream, continuation) = CurrentValueStream.makeStream(initial: 0)
    var counter = 0
    let valuesReceived = expectation(description: "All values received")

    let inc: @Sendable () -> Void = {
      Task { @MainActor in
        counter += 1
        if counter == 10 { // 5 values × 2 subscribers
          valuesReceived.fulfill()
        }
      }
    }

    Task {
      for await _ in stream {
        inc()
      }
    }

    Task {
      for await _ in stream {
        inc()
      }
    }

    for i in 1...5 {
      continuation.yield(i)
    }

    try await fulfillment(of: [valuesReceived])
    #expect(stream.value == 5)
  }

  @Test("CurrentValueStream dynamic member lookup")
  func test_dynamicMemberLookup() async throws {
    struct TestStruct {
      let value: Int
      let text: String
    }

    let initial = TestStruct(value: 1, text: "test")
    let stream = CurrentValueStream.Just(initial)

    #expect(stream.value.value == 1)
    #expect(stream.text == "test")
  }

  @Test("last value")
  func test_lastValue() async throws {
    let (stream, continuation) = CurrentValueStream<Int>.makeStream(initial: 1)
    continuation.yield(2)
    continuation.finish()

    #expect(await stream.lastValue == 2)
  }

  @Test("last value is the first value when the stream has no updates")
  func test_lastValue_unchangedStream() async throws {
    let (stream, continuation) = CurrentValueStream<Int>.makeStream(initial: 1)
    continuation.finish()

    #expect(await stream.lastValue == 1)
  }

  @Test("last value is the fixed value with Just")
  func test_lastValue_justStream() async throws {
    let stream = CurrentValueStream<Int>.Just(1)
    #expect(await stream.lastValue == 1)
  }

  @Test("Just updates complete immediately")
  func test_justStream_hasNoUpdates() async throws {
    let stream = CurrentValueStream<Int>.Just(1)
    var updatesCount = 0
    for await _ in stream.updates {
      updatesCount += 1
    }
    #expect(updatesCount == 1)
  }
}

// MARK: - MutableCurrentValueStreamTests

struct MutableCurrentValueStreamTests {
  @Test("MutableCurrentValueStream can be updated")
  func test_update() async throws {
    let stream = MutableCurrentValueStream(0)
    #expect(stream.value == 0)

    let updates = expectation(description: "Updates received")
    var receivedValues = [Int]()

    Task {
      for await value in stream {
        receivedValues.append(value)
        if receivedValues.count == 3 {
          updates.fulfill()
        }
      }
    }

    stream.update(with: 1)
    stream.update(with: 2)
    stream.update(with: 3)

    try await fulfillment(of: [updates])
    #expect(receivedValues == [1, 2, 3])
    #expect(stream.value == 3)
  }

  @Test("MutableCurrentValueStream can be finished")
  func test_finish() async throws {
    let stream = MutableCurrentValueStream(0)
    let completion = expectation(description: "Stream completed")

    Task {
      var count = 0
      for await _ in stream {
        count += 1
      }
      #expect(count == 2)
      completion.fulfill()
    }

    stream.update(with: 1)
    stream.update(with: 2)
    stream.finish()

    try await fulfillment(of: [completion])
  }

  @Test("MutableCurrentValueStream maintains value after finish")
  func test_valueAfterFinish() async throws {
    let stream = MutableCurrentValueStream(0)
    stream.update(with: 42)
    stream.finish()

    #expect(stream.value == 42)
  }
}
