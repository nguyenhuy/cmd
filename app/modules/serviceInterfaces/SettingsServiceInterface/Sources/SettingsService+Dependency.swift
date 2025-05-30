// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - SettingsServiceDependencyKey

public final class SettingsServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: SettingsService = MockSettingsService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: SettingsService = () as! SettingsService
  #endif
}

extension DependencyValues {
  public var settingsService: SettingsService {
    get { self[SettingsServiceDependencyKey.self] }
    set { self[SettingsServiceDependencyKey.self] = newValue }
  }
}
