// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - ShellServiceDependencyKey

public final class ShellServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: ShellService = MockShellService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: ShellService = () as! ShellService
  #endif
}

extension DependencyValues {
  public var shellService: ShellService {
    get { self[ShellServiceDependencyKey.self] }
    set { self[ShellServiceDependencyKey.self] = newValue }
  }
}
