// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import SwiftTesting
import Testing
@testable import ConcurrencyFoundation

// MARK: - BroadcastedStreamTests

struct BroadcastedStreamTests {
  @Test("Stream can be multiplexed")
  func test_multiplex() async throws {
    let (stream, continuation) = BroadcastedStream<Int>.makeStream()
    let valuesReceived = expectation(description: "All values received")
    let stream1Completed = expectation(description: "Stream 1 completed")
    let stream2Completed = expectation(description: "Stream 2 completed")

    var values1: [Int] = []
    var values2: [Int] = []

    Task {
      for await value in stream {
        values1.append(value)
      }
      stream1Completed.fulfill()
    }
    Task {
      for await value in stream {
        values2.append(value)
      }
      stream2Completed.fulfill()
    }

    for i in 0..<5 {
      continuation.yield(i)
    }

    // Wait a bit to ensure values are received
    try await Task.sleep(for: .milliseconds(100))
    valuesReceived.fulfill()

    continuation.finish()
    try await fulfillment(of: [valuesReceived, stream1Completed, stream2Completed])

    #expect(values1 == [0, 1, 2, 3, 4])
    #expect(values2 == [0, 1, 2, 3, 4])
  }

  @Test("Stream receives already emitted values")
  func test_streamHistory() async throws {
    let (stream, continuation) = BroadcastedStream<Int>.makeStream()
    for i in 0..<5 {
      continuation.yield(i)
    }
    continuation.finish()

    var values = [Int]()
    for await i in stream {
      values.append(i)
    }

    #expect(values == [0, 1, 2, 3, 4])
  }

  @Test("Late subscribers receive full history")
  func test_lateSubscriber() async throws {
    let (stream, continuation) = BroadcastedStream<Int>.makeStream()

    // First emit some values
    for i in 0..<3 {
      continuation.yield(i)
    }

    // Late subscriber should receive all previous values
    var lateValues = [Int]()
    let lateSubscriberDone = expectation(description: "Late subscriber completed")

    Task {
      for await value in stream {
        lateValues.append(value)
      }
      lateSubscriberDone.fulfill()
    }

    // Emit more values
    for i in 3..<5 {
      continuation.yield(i)
    }

    continuation.finish()
    try await fulfillment(of: [lateSubscriberDone])

    #expect(lateValues == [0, 1, 2, 3, 4])
  }

  @Test("Stream from publisher")
  func test_publisherStream() async throws {
    let subject = PassthroughSubject<Int, Never>()
    var freezeStream: (() -> Void)?

    let stream = BroadcastedStream(subject.eraseToAnyPublisher()) { finish in
      freezeStream = finish
    }

    let valuesReceived = expectation(description: "Values received")
    let streamFinished = expectation(description: "Stream finished received")
    var receivedValues = [Int]()

    Task {
      for await value in stream {
        receivedValues.append(value)
        if receivedValues.count == 3 {
          valuesReceived.fulfill()
        }
      }
      streamFinished.fulfill()
    }

    subject.send(1)
    subject.send(2)
    subject.send(3)
    try await fulfillment(of: [valuesReceived])
    freezeStream?()

    try await fulfillment(of: [streamFinished])
    #expect(receivedValues == [1, 2, 3])
  }

  @Test("Just stream")
  func test_just() async throws {
    let stream = BroadcastedStream.Just(42)
    var values = [Int]()
    let completion = expectation(description: "Stream completed")

    Task {
      for await value in stream {
        values.append(value)
      }
      completion.fulfill()
    }

    try await fulfillment(of: [completion])
    #expect(values == [42])
  }

  @Test("Stream finishes for all subscribers")
  func test_completion() async throws {
    let (stream, continuation) = BroadcastedStream<Int>.makeStream()
    let sub1Done = expectation(description: "Subscriber 1 completed")
    let sub2Done = expectation(description: "Subscriber 2 completed")

    Task {
      for await _ in stream { }
      sub1Done.fulfill()
    }

    Task {
      for await _ in stream { }
      sub2Done.fulfill()
    }

    continuation.yield(1)
    continuation.finish()

    try await fulfillment(of: [sub1Done, sub2Done])
  }
}
