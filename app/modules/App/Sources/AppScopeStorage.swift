// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

@dynamicMemberLookup
final class AppScopeStorage<InitialDependencies: Sendable>: @unchecked Sendable {

  init(initial: InitialDependencies) {
    self.initial = initial
  }

  /// Lazily creates a memoized instance of a dependency.
  func shared<T: Sendable>(key: String = #function, _ build: @Sendable () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    if let instance = dependencies[key] as? T { return instance }
    let instance = build()
    dependencies[key] = instance
    return instance
  }

  subscript<T>(dynamicMember keyPath: KeyPath<InitialDependencies, T>) -> T {
    initial[keyPath: keyPath]
  }

  private let initial: InitialDependencies

  private var dependencies: [String: Sendable] = [:]

  /// The lock that should be used to synchronize access to the dependencies.
  ///
  /// Recursive lock to allow for shared access to the dependencies from within the `shared` method.
  private let lock = NSRecursiveLock()
}
