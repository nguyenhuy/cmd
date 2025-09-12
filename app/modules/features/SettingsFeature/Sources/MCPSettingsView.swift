// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import DLS
import MCPServiceInterface
import SwiftUI

// MARK: - MCPSettingsView

public struct MCPSettingsView: View {
  public init() {}
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // MCP Server cards
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(sampleMCPServers, id: \.name) { server in
            MCPServerCard(
              server: server,
              isEnabled: enabledServers[server.name] != nil,
              onToggle: { isEnabled in
                if isEnabled {
                  enabledServers[server.name] = .stdio(.init(
                    name: server.name,
                    command: "npx",
                    args: ["@modelcontextprotocol/server-\(server.name)"]
                  ))
                } else {
                  enabledServers.removeValue(forKey: server.name)
                }
              })
          }
        }
        .padding(.bottom, 20)
      }
    }
  }
  
  @State private var enabledServers: [String: MCPServerConfiguration] = [:]
}

// MARK: - MCPServer

private struct MCPServer {
  let name: String
  let description: String
}

// MARK: - Sample Data

private let sampleMCPServers: [MCPServer] = [
  MCPServer(
    name: "filesystem",
    description: "Secure file operations"),
  MCPServer(
    name: "sqlite",
    description: "SQLite database operations"),
  MCPServer(
    name: "brave-search",
    description: "Web search functionality"),
  MCPServer(
    name: "fetch",
    description: "HTTP requests and web content"),
  MCPServer(
    name: "github",
    description: "GitHub repository operations"),
  MCPServer(
    name: "postgres",
    description: "PostgreSQL database operations")
]

// MARK: - MCPServerCard

private struct MCPServerCard: View {
  let server: MCPServer
  let isEnabled: Bool
  let onToggle: (Bool) -> Void
  
  var body: some View {
    HStack(spacing: 16) {
      // Server info
      VStack(alignment: .leading, spacing: 4) {
        Text(server.name)
          .font(.headline)
          .foregroundColor(.primary)
        Text(server.description)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      // Toggle switch
      Toggle("", isOn: Binding(
        get: { isEnabled },
        set: { newValue in
          onToggle(newValue)
        }
      ))
      .toggleStyle(SwitchToggleStyle())
    }
    .padding(16)
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1))
  }
}
