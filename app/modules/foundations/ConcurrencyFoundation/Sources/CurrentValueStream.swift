// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Combine
import Foundation
import os

// MARK: - CurrentValueStream

/// Similar to `CurrentValueSubject`, but it's a stream so it supports completion.
///
/// This stream can be subscribed to by several subscribers, concurrently or not. Each subscribers will receive all updates since the beginning of the stream.
@dynamicMemberLookup
public class CurrentValueStream<Element: Sendable>: @unchecked Sendable, Identifiable, AsyncSequence {

  /// Initialize with a publisher that emits updates.
  public convenience init(
    initial: Element,
    publisher: AnyPublisher<Element, Never>,
    _ finish: (() -> Void) -> Void)
  {
    self.init(initial, stream: .init(publisher, finish))
  }

  /// Initialize with a stream that emits updates, and signal when the updates are done.
  public convenience init(initial: Element, stream: AsyncStream<Element>) {
    self.init(initial, stream: .init(stream))
  }

  public convenience init(value: CurrentValueSubject<Element, Never>) {
    self.init(initial: value.value, publisher: value.eraseToAnyPublisher()) { _ in }
  }

  init(_ initial: Element, stream: BroadcastedStream<Element>) {
    let (internalStream, continuation) = BroadcastedStream<Element>.makeStream()
    self.internalStream = internalStream
    lock = .init(initialState: InternalState(value: initial))
    Task { [weak self] in
      for try await value in stream {
        self?.updateFrom(streamedValue: value)
        continuation.yield(value)
      }
      continuation.finish()
    }
  }

  public typealias AsyncIterator = AsyncStream<Element>.Iterator
  public typealias Failure = Never
  public typealias Continuation = AsyncStream<Element>.Continuation

  /// A unique identifier for the value.
  public let id = UUID()

  /// The current value.
  public var value: Element {
    lock.withLock { $0.value }
  }

  public var updates: CurrentValueStream<Element> {
    self
  }

  /// Return the last value of the stream. If the stream is not yet finished, wait for it to finish.
  public var lastValue: Element {
    get async {
      var result = self.value
      for await value in self.updates {
        result = value
      }
      return result
    }
  }

  public static func Just(_ value: Element) -> CurrentValueStream<Element> {
    CurrentValueStream(initial: value, publisher: Combine.Just(value).eraseToAnyPublisher()) { finish in finish() }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    internalStream.makeAsyncIterator()
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> T {
    value[keyPath: keyPath]
  }

  let internalStream: BroadcastedStream<Element>

  /// Set the current value.
  func set(currentValue: Element) {
    lock.withLock { $0.value = currentValue }
  }

  /// Handle receiving a value from the internal stream.
  func updateFrom(streamedValue value: Element) {
    set(currentValue: value)
  }

  private struct InternalState {
    var value: Element
  }

  private let lock: OSAllocatedUnfairLock<InternalState>

}

extension CurrentValueStream {
  public static func makeStream(initial: Element)
    -> (stream: CurrentValueStream<Element>, continuation: AsyncStream<Element>.Continuation)
  {
    let (stream, continuation) = AsyncStream<Element>.makeStream()
    let broadcastedStream = CurrentValueStream<Element>(initial: initial, stream: stream)
    return (broadcastedStream, continuation)
  }
}

// MARK: - MutableCurrentValueStream

/// A value that can be observed for changes. The owner of this value can modify it. It can be shared in a read-only mode through its super class `CurrentValueStream`.
public final class MutableCurrentValueStream<Element: Sendable>: CurrentValueStream<Element>, @unchecked Sendable {

  public init(_ initial: Element) {
    let (stream, continuation) = CurrentValueStream<Element>.makeStream(initial: initial)
    self.continuation = continuation
    super.init(initial, stream: stream.internalStream)
  }

  public func update(with value: Element) {
    // Set the current value immediately.
    // This helps ensure that the value is not set with a delay due to thread hops when read from the stream.
    set(currentValue: value)
    continuation.yield(value)
  }

  public func finish() {
    continuation.finish()
  }

  override func updateFrom(streamedValue _: Element) {
    // Do nothing here, since the value has already been set in `update(with:)`.
  }

  private let continuation: AsyncStream<Element>.Continuation
}
