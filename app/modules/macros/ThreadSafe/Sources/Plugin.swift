// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@_exported import ConcurrencyFoundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Define the ThreadSafe macro
@attached(member, names: named(_internalState), named(_InternalState), named(inLock))
@attached(memberAttribute)
public macro ThreadSafe() = #externalMacro(module: "ThreadSafeMacro", type: "ThreadSafeMacro")

/// Define the ThreadSafeProperty macro
@attached(accessor)
public macro ThreadSafeProperty() = #externalMacro(module: "ThreadSafeMacro", type: "ThreadSafePropertyMacro")

/// Define the ThreadSafeProperty macro
@attached(body)
public macro ThreadSafeInitializer(_ params: [String: Any]) = #externalMacro(
  module: "ThreadSafeMacro",
  type: "ThreadSafeInitializerMacro")

// MARK: - TypeInfo

public struct TypeInfo<T> {
  let defaultValue: T?

  public init(defaultValue: T? = nil) {
    self.defaultValue = defaultValue
  }
}
