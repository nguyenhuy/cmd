// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies

// MARK: - PermissionsServiceDependencyKey

public final class PermissionsServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: PermissionsService = MockPermissionsService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: PermissionsService = () as! PermissionsService
  #endif
}

extension DependencyValues {
  public var permissionsService: PermissionsService {
    get { self[PermissionsServiceDependencyKey.self] }
    set { self[PermissionsServiceDependencyKey.self] = newValue }
  }
}
