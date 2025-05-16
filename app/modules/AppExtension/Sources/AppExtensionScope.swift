// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import DependencyFoundation
import Foundation
import ThreadSafe

// MARK: - AppExtensionScope

@ThreadSafe
public final class AppExtensionScope: Sendable, BaseProviding {

  init() { }

  public static let shared = AppExtensionScope()

  public func _shared<T: Sendable>(key: String, _ build: @Sendable () -> T) -> T {
    sharedDependencies.shared(key: key, build)
  }

  static func shared<T: Sendable>(key: String = #function, _ build: @Sendable () -> T) -> T {
    shared.shared(key: key, build)
  }

  private var sharedDependencies = AppScopeStorage()

}

// MARK: - AppScopeStorage

final class AppScopeStorage: @unchecked Sendable {

  init() { }

  /// Lazily creates a memoized instance of a dependency.
  func shared<T: Sendable>(key: String = #function, _ build: @Sendable () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    if let instance = dependencies[key] as? T { return instance }
    let instance = build()
    dependencies[key] = instance
    return instance
  }

  private var dependencies: [String: Sendable] = [:]

  /// The lock that should be used to synchronize access to the dependencies.
  ///
  /// Recursive lock to allow for shared access to the dependencies from within the `shared` method.
  private let lock = NSRecursiveLock()
}
