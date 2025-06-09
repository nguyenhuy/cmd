// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

// MARK: - UncheckedSendable

/// A helper to send non Sendable variables, as the variables cannot be directly annotated with @unchecked Sendable.
public final class UncheckedSendable<Value>: @unchecked Sendable {

  public init(_ value: Value) {
    wrapped = value
  }

  public let wrapped: Value

}
