// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import DependencyFoundation

// MARK: - MCPService

/// Service for managing MCP (Model Context Protocol) server settings and configuration.
public protocol MCPService: Sendable {
  /// Load MCP settings from persistent storage.
  func loadSettings() async throws -> MCPSettings
  
  /// Save MCP settings to persistent storage.
  func saveSettings(_ settings: MCPSettings) async throws
}

// MARK: - MCPSettings

public struct MCPSettings: Sendable, Codable {
  /// Set of enabled MCP server names
  public let enabledServers: Set<String>
  
  public init(enabledServers: Set<String>) {
    self.enabledServers = enabledServers
  }
}

// MARK: - MCPServiceProviding

public protocol MCPServiceProviding {
  var mcpService: MCPService { get }
}

public enum MCPServerConfiguration {
    case stdio(_ configuration: MCPServerStdioConfiguration)
    case http(_ configuration: MCPServerHttpConfiguration)
    
    public var name: String {
        switch self {
        case .stdio(let config):
            return config.name
        case .http(let config):
            return config.name
        }
    }
    
    public var disabled: Bool {
        switch self {
        case .stdio(let config):
            return config.disabled
        case .http(let config):
            return config.disabled
        }
    }
    
    public var autoApprove: [String]? {
        switch self {
        case .stdio(let config):
            return config.autoApprove
        case .http(let config):
            return config.autoApprove
        }
    }
    
    public struct MCPServerStdioConfiguration {
        public let name: String
        public let command: String
        public let args: [String]?
        public let env: [String: String]?
        public let disabled: Bool
        public let autoApprove: [String]?
        
        public init(name: String, command: String, args: [String]? = nil, env: [String: String]? = nil, disabled: Bool = false, autoApprove: [String]? = nil) {
            self.name = name
            self.command = command
            self.args = args
            self.env = env
            self.disabled = disabled
            self.autoApprove = autoApprove
        }
    }
    
    public struct MCPServerHttpConfiguration {
        public let name: String
        public let url: String
        public let headers: [String: String]?
        public let disabled: Bool
        public let autoApprove: [String]?
        
        public init(name: String, url: String, headers: [String: String]? = nil, disabled: Bool = false, autoApprove: [String]? = nil) {
            self.name = name
            self.url = url
            self.headers = headers
            self.disabled = disabled
            self.autoApprove = autoApprove
        }
    }
}
