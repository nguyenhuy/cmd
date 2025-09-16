// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SettingsServiceInterface
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockMCPService: MCPService {

  public init() { }

  public var onLoadSettings: @Sendable () async throws -> MCPSettings = {
    [:]
  }

  public var onSaveSettings: @Sendable (MCPSettings) async throws -> Void = { _ in }

  public var onConnect: @Sendable (MCPServerConfiguration) async throws -> Void = { _ in }

  public func loadSettings() async throws -> MCPSettings {
    try await onLoadSettings()
  }

  public func saveSettings(_ settings: MCPSettings) async throws {
    try await onSaveSettings(settings)
  }

  public func connect(to server: MCPServerConfiguration) async throws {
    try await onConnect(server)
  }
}
#endif
