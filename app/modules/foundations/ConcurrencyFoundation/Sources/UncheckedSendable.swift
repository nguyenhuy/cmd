// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

// MARK: - UncheckedSendable

/// A helper to send non Sendable variables, as the variables cannot be directly annotated with @unchecked Sendable.
public final class UncheckedSendable<Value>: @unchecked Sendable {

  public init(_ value: Value) {
    wrapped = value
  }

  public let wrapped: Value

}
