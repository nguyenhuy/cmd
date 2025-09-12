// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockMCPService: MCPService {
  
  public init() {}
  
  public var onLoadSettings: @Sendable () async throws -> MCPSettings = {
    MCPSettings(enabledServers: [:])
  }
  
  public var onSaveSettings: @Sendable (MCPSettings) async throws -> Void = { _ in }
  
  public func loadSettings() async throws -> MCPSettings {
    try await onLoadSettings()
  }
  
  public func saveSettings(_ settings: MCPSettings) async throws {
    try await onSaveSettings(settings)
  }
}
#endif
