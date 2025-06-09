// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

@preconcurrency import Combine
import DependencyFoundation
import LoggingService
import LoggingServiceInterface
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
    inLock { $0.sharedDependencies = AppScopeStorage(initial: initialDependencies) }

    setupLogging()
  }

  func _shared<T: Sendable>(key: String, _ build: @Sendable () -> T) -> T {
    sharedDependencies!.shared(key: key, build)
  }

  private var cancellables = Set<AnyCancellable>()

  private func setupLogging() {
    let logger = DefaultLogger(
      subsystem: defaultLogger.subsystem,
      category: defaultLogger.category,
      fileManager: fileManager)
    /// Override the default global logger. This is not thread safe. By doing it very early in the lifecycle there should be little change of this causing a crash.
    defaultLogger = logger

    AppScope.shared.settingsService.liveValue(for: \.allowAnonymousAnalytics).sink { [weak logger] allowAnonymousAnalytics in
      if allowAnonymousAnalytics {
        logger?.startExternalLogging()
      } else {
        logger?.stopExternalLogging()
      }
    }.store(in: &cancellables)
  }

}
