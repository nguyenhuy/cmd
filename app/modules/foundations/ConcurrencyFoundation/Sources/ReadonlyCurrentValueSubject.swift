// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine

// MARK: - ReadonlyCurrentValueSubject

/// Like `CurrentValueSubject`, but does not allow to mutate the value.
public final class ReadonlyCurrentValueSubject<Output: Sendable, Failure: Error>: Publisher, Sendable {

  public init(_ value: Output, publisher: AnyPublisher<Output, Failure>) {
    self.value = Atomic(value)
    self.publisher = publisher
  }

  public convenience init(_ value: CurrentValueSubject<Output, Failure>) {
    self.init(value.value, publisher: value.eraseToAnyPublisher())
  }

  public var currentValue: Output {
    value.value
  }

  public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
    publisher.receive(subscriber: subscriber)
  }

  private let value: Atomic<Output>
  private let publisher: AnyPublisher<Output, Failure>

}

extension CurrentValueSubject where Output: Sendable {
  public func readonly() -> ReadonlyCurrentValueSubject<Output, Failure> {
    ReadonlyCurrentValueSubject(value, publisher: eraseToAnyPublisher())
  }
}

extension CurrentValueSubject where Output: Sendable & Equatable {
  public func readonly(removingDuplicate: Bool) -> ReadonlyCurrentValueSubject<Output, Failure> {
    if removingDuplicate {
      ReadonlyCurrentValueSubject(value, publisher: removeDuplicates().eraseToAnyPublisher())
    } else {
      readonly()
    }
  }
}
