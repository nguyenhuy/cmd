// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

public enum MCPServerConfiguration: Sendable, Equatable {
  case stdio(_ configuration: MCPServerStdioConfiguration)
  case http(_ configuration: MCPServerHttpConfiguration)

  public struct MCPServerStdioConfiguration: Sendable, Equatable {
    public init(
      name: String,
      command: String,
      args: [String]? = nil,
      env: [String: String]? = nil,
      disabled: Bool = false,
      autoApprove: [String]? = nil)
    {
      self.name = name
      self.command = command
      self.args = args
      self.env = env
      self.disabled = disabled
      self.autoApprove = autoApprove
    }

    public var name: String
    public var command: String
    public var args: [String]?
    public var env: [String: String]?
    public var disabled: Bool
    public var autoApprove: [String]?

  }

  public struct MCPServerHttpConfiguration: Sendable, Equatable {
    public var name: String
    public var url: String
    public var headers: [String: String]?
    public var disabled: Bool
    public var autoApprove: [String]?

    public init(
      name: String,
      url: String,
      headers: [String: String]? = nil,
      disabled: Bool = false,
      autoApprove: [String]? = nil)
    {
      self.name = name
      self.url = url
      self.headers = headers
      self.disabled = disabled
      self.autoApprove = autoApprove
    }
  }

  public var name: String {
    switch self {
    case .stdio(let config):
      config.name
    case .http(let config):
      config.name
    }
  }

  public var disabled: Bool {
    get {
      switch self {
      case .stdio(let config):
        config.disabled
      case .http(let config):
        config.disabled
      }
    }
    set {
      switch self {
      case .stdio(var config):
        config.disabled = newValue
        self = .stdio(config)

      case .http(var config):
        config.disabled = newValue
        self = .http(config)
      }
    }
  }

  public var autoApprove: [String]? {
    switch self {
    case .stdio(let config):
      config.autoApprove
    case .http(let config):
      config.autoApprove
    }
  }

}
