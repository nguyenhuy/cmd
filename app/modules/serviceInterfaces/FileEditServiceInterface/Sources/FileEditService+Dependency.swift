// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - FileEditServiceDependencyKey

public final class FileEditServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: FileEditService = MockFileEditService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: FileEditService = () as! FileEditService
  #endif
}

extension DependencyValues {
  public var fileEditService: FileEditService {
    get { self[FileEditServiceDependencyKey.self] }
    set { self[FileEditServiceDependencyKey.self] = newValue }
  }
}
