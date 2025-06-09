// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
