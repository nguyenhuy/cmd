// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import DependencyFoundation
import ThreadSafe

// MARK: - AppScope
@ThreadSafe
final class AppScope: Sendable, BaseProviding {

  init() { }

  struct InitialDependencies: Sendable {
    let isAppActive: AnyPublisher<Bool, Never>
  }

  static let shared = AppScope()

  var sharedDependencies: AppScopeStorage<InitialDependencies>?

  static func shared<T: Sendable>(key: String = #function, _ build: @Sendable () -> T) -> T {
    shared.shared(key: key, build)
  }

  @MainActor
  func create(isAppActive: AnyPublisher<Bool, Never>) {
    let initialDependencies = InitialDependencies(isAppActive: isAppActive)
    safelyMutate { $0.sharedDependencies = AppScopeStorage(initial: initialDependencies) }
  }

  func _shared<T: Sendable>(key: String, _ build: @Sendable () -> T) -> T {
    sharedDependencies!.shared(key: key, build)
  }

}
