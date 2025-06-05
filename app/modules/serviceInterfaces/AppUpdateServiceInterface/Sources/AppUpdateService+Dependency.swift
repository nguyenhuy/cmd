// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - AppUpdateServiceDependencyKey

public final class AppUpdateServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: AppUpdateService = MockAppUpdateService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: AppUpdateService = () as! AppUpdateService
  #endif
}

extension DependencyValues {
  public var appUpdateService: AppUpdateService {
    get { self[AppUpdateServiceDependencyKey.self] }
    set { self[AppUpdateServiceDependencyKey.self] = newValue }
  }
}
