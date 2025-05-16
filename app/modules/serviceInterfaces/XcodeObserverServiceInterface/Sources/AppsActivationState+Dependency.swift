// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import Dependencies

// MARK: - AppsActivationStateDependencyKey

public final class AppsActivationStateDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: AnyPublisher<AppsActivationState, Never> = AppsActivationState.mockPublisher()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: AnyPublisher<AppsActivationState, Never> = () as! AnyPublisher<AppsActivationState, Never>
  #endif
}

extension DependencyValues {
  public var appsActivationState: AnyPublisher<AppsActivationState, Never> {
    get { self[AppsActivationStateDependencyKey.self] }
    set { self[AppsActivationStateDependencyKey.self] = newValue }
  }
}
