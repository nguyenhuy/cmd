// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - ServerDependencyKey

public final class ServerDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: Server = MockServer()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: Server = () as! Server
  #endif
}

extension DependencyValues {
  public var server: Server {
    get { self[ServerDependencyKey.self] }
    set { self[ServerDependencyKey.self] = newValue }
  }
}
