// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import LSTool

// MARK: - LSToolEncodingTests

struct LSToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - non-recursive")
  func test_toolUseEncodingDecodingNonRecursive() throws {
    let tool = LSTool()
    let input = LSTool.Use.Input(
      path: "/project",
      recursive: false)
    let use = tool.use(toolUseId: "ls-123", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
      {
        "callingTool": "list_files",
        "context": {},
        "input": {
          "path": "/project",
          "recursive": false
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "ls-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - recursive")
  func test_toolUseEncodingDecodingRecursive() throws {
    let tool = LSTool()
    let input = LSTool.Use.Input(
      path: "/workspace/src",
      recursive: true)
    let use = tool.use(toolUseId: "ls-recursive-456", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
      {
        "callingTool": "list_files",
        "context": {},
        "input": {
          "path": "/workspace/src",
          "recursive": true
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "ls-recursive-456"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - path only")
  func test_toolUseEncodingDecodingPathOnly() throws {
    let tool = LSTool()
    let input = LSTool.Use.Input(
      path: "/home/user/projects",
      recursive: nil)
    let use = tool.use(toolUseId: "ls-structure-789", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
      {
        "callingTool": "list_files",
        "context": {},
        "input": {
          "path": "/home/user/projects"
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "ls-structure-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)

private func testDecodingEncodingWithTool(
  of value: some Codable,
  tool: any Tool,
  _ json: String)
  throws
{
  // Create decoder with tool plugin
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)
  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  // Create encoder
  let encoder = JSONEncoder()

  // Use the test function with proper decoder/encoder
  try testDecodingEncoding(of: value, json, decoder: decoder, encoder: encoder)
}
