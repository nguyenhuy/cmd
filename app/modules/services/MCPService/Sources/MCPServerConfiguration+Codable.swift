// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Foundation
import MCPServiceInterface

// MARK: - MCPServerConfiguration Codable Support

extension MCPServerConfiguration {
  private enum CodingKeys: String, CodingKey {
    case type
  }
  
  private enum ServerType: String, Codable {
    case stdio
    case http
  }
  
    public init(from decoder: Decoder, name: String) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(ServerType.self, forKey: .type)
    
    switch type {
    case .stdio:
        let config = try MCPServerStdioConfiguration(from: decoder, name: name)
      self = .stdio(config)
    case .http:
      let config = try MCPServerHttpConfiguration(from: decoder, name: name)
      self = .http(config)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .stdio(let config):
      try container.encode(ServerType.stdio, forKey: .type)
      try config.encode(to: encoder)
    case .http(let config):
      try container.encode(ServerType.http, forKey: .type)
      try config.encode(to: encoder)
    }
  }
}

// MARK: - MCPServerStdioConfiguration Codable Support

extension MCPServerConfiguration.MCPServerStdioConfiguration {
    public init(from decoder: any Decoder, name: String) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let command = try container.decode(String.self, forKey: .command)
        let args = try container.decodeIfPresent([String].self, forKey: .args) ?? []
        let env = try container.decodeIfPresent([String: String].self, forKey: .env) ?? [:]
        let disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled) ?? false
        let autoApprove = try container.decodeIfPresent([String].self, forKey: .autoApprove)
        
        self.init(
            name: name,
            command: command,
            args: args,
            env: env,
            disabled: disabled,
            autoApprove: autoApprove
        )
    }
    
    
     
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(env, forKey: .env)
        try container.encode(disabled, forKey: .disabled)
        try container.encodeIfPresent(autoApprove, forKey: .autoApprove)
    }
    
  private enum CodingKeys: String, CodingKey {
    case command
    case args
    case env
    case disabled
    case autoApprove
  }
}

// MARK: - MCPServerHttpConfiguration Codable Support

extension MCPServerConfiguration.MCPServerHttpConfiguration {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(headers, forKey: .headers)
        try container.encode(disabled, forKey: .disabled)
        try container.encodeIfPresent(autoApprove, forKey: .autoApprove)
    }
    
    public init(from decoder: any Decoder, name: String) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(String.self, forKey: .url)
        let headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        let disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled) ?? false
        let autoApprove = try container.decodeIfPresent([String].self, forKey: .autoApprove)
        
        self.init(
            name: name,
            url: url,
            headers: headers,
            disabled: disabled,
            autoApprove: autoApprove
        )
    }
    
  private enum CodingKeys: String, CodingKey {
    case url
    case headers
    case disabled
    case autoApprove
  }
}

// MARK: - Dictionary Decoding Support

public struct MCPServerConfigurations: Codable {
    public var configurations: [String: MCPServerConfiguration]
    
    public init(from decoder: Decoder) throws {
        var result: [String: MCPServerConfiguration] = [:]
        
        let container = try decoder.container(keyedBy: String.self)
        let serverNames = container.allKeys
        for serverName in serverNames {
            let nestedDecoder = try container.superDecoder(forKey: serverName)
            result[serverName] = try MCPServerConfiguration(from: nestedDecoder, name: serverName)
        }
        self.configurations = result
    }
      public func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: String.self)
          for (key, value) in configurations {
              var nestedContainer = container.nestedContainer(keyedBy: String.self, forKey: key)
              try value.encode(to: nestedContainer.superEncoder())
          }
      }
}
