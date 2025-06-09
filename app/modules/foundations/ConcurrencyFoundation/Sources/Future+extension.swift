// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Combine

extension Future {

  /// Similar to `init(_:)`, but the closure is allowed to be `@Sendable`.
  public convenience init(_ sendableAttemptToFulfill: @escaping (@Sendable @escaping (Result<Output, Failure>) -> Void) -> Void) {
    self.init { attemptToFulfill in
      let uncheckedSendable = UncheckedSendable(attemptToFulfill)
      sendableAttemptToFulfill { result in
        uncheckedSendable.wrapped(result)
      }
    }
  }

  public static func make() -> (Future<Output, Failure>, @Sendable (Result<Output, Failure>) -> Void) {
    var promise: (Result<Output, Failure>) -> Void = { _ in }
    let future = Future { p in
      promise = p
    }

    let uncheckedSendable = UncheckedSendable(promise)
    let completion: @Sendable (Result<Output, Failure>) -> Void = { result in
      uncheckedSendable.wrapped(result)
    }
    return (future, completion)
  }

  public static func Just(_ output: Output) -> Future<Output, Failure> {
    Future { $0(.success(output)) }
  }
}
