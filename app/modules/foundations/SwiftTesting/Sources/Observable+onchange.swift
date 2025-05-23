// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import Foundation
import Observation

extension Observable where Self: Sendable {
  /// When the value of a at a given key path changes, this function will be called.
  public func didSet<Value: Sendable>(
    _ keyPath: KeyPath<Self, Value>,
    perform action: @Sendable @escaping (Value) -> Void)
    -> Cancellable
  {
    let cancellable = AnyCancellable { }
    withObservationTracking(
      {
        _ = self[keyPath: keyPath]
      },
      token: { [weak cancellable] in
        guard let cancellable else { return nil }
        _ = cancellable
        return ""
      },
      willChange: nil,
      didChange: {
        action(self[keyPath: keyPath])
      })
    return cancellable
  }
}

// extension KeyPath: @retroactive @unchecked Sendable { }

func withObservationTracking(
  _ apply: @Sendable @escaping () -> Void,
  token: @Sendable @escaping () -> String?,
  willChange: (@Sendable () -> Void)? = nil,
  didChange: @escaping @Sendable () -> Void)
{
  withObservationTracking(apply) {
    guard token() != nil else { return }
    willChange?()
    RunLoop.current.perform {
      didChange()
      withObservationTracking(
        apply,
        token: token,
        willChange: willChange,
        didChange: didChange)
    }
  }
}
