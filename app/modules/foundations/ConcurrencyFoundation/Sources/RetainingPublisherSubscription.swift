// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine

// MARK: - RetainingPublisherSubscription

/// A subscription that will retain a given object until it is cancelled.
///
/// This is particularly useful when working with custom publishers that needs to be retained while they are subscribed to.
public final class RetainingPublisherSubscription<Output>: Subscription {

  public init<S: Subscriber>(
    retained: AnyObject,
    publisher: any Publisher<Output, Never>,
    subscriber: S) where S.Input == Output, S.Failure == Never
  {
    self.retained = retained

    subjectCancellable = publisher.sink(receiveCompletion: { completion in
      subscriber.receive(completion: completion)
    }, receiveValue: { value in
      _ = subscriber.receive(value)
    })
  }

  /// The subscriber may signal demand.
  /// You could honor this in more complex publishers.
  public func request(_: Subscribers.Demand) {
    // Typically ignored or stored, depending on your publisher's requirements.
  }

  /// Cancel is called when the subscriber goes away or explicitly cancels.
  public func cancel() {
    // Break the strong references so everything can deinit
    subjectCancellable = nil
    retained = nil
  }

  private var retained: AnyObject?
  private var subjectCancellable: AnyCancellable?

}
