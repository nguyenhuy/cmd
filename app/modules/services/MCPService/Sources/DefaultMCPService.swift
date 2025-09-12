// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppFoundation
import DependencyFoundation
import Foundation
import FoundationInterfaces
import JSONFoundation
import LoggingServiceInterface
import MCPServiceInterface
import SettingsServiceInterface

// MARK: - DefaultMCPService

final class DefaultMCPService: MCPService {
  
  // MARK: - Initialization
  
  init(
    settingsService: SettingsService,
    fileManager: FileManagerI
  ) {
    self.settingsService = settingsService
    self.fileManager = fileManager
  }
  
  // MARK: - MCPService
  
  func loadSettings() async throws -> MCPSettings {
    let settingsURL = try mcpSettingsURL()
    
    guard fileManager.fileExists(atPath: settingsURL.path) else {
      // Return default settings if file doesn't exist
      return MCPSettings(enabledServers: [:])
    }
    
    let data = try Data(contentsOf: settingsURL)
    return try JSONDecoder().decode(MCPSettings.self, from: data)
  }
  
  func saveSettings(_ settings: MCPSettings) async throws {
    let settingsURL = try mcpSettingsURL()
    
    // Create directory if it doesn't exist
    let settingsDirectory = settingsURL.deletingLastPathComponent()
    try fileManager.createDirectory(
      at: settingsDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )
    
    let data = try JSONEncoder.sortingKeys.encode(settings)
    try data.write(to: settingsURL)
  }
  
  // MARK: - Private
  
  private let settingsService: SettingsService
  private let fileManager: FileManagerI
  
  private func mcpSettingsURL() throws -> URL {
    return FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".cmd")
      .appendingPathComponent("mcp-settings.json")
  }
}

// MARK: - Dependency Registration

extension BaseProviding where
  Self: SettingsServiceProviding,
  Self: FileManagerProviding
{
  public var mcpService: MCPService {
    shared {
      DefaultMCPService(
        settingsService: settingsService,
        fileManager: fileManager
      )
    }
  }
}
