// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import ExecuteCommandTool

// MARK: - ExecuteCommandToolEncodingTests

struct ExecuteCommandToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - basic command")
  func test_toolUseEncodingDecodingBasic() throws {
    let tool = ExecuteCommandTool()
    let input = ExecuteCommandTool.Use.Input(
      command: "pwd",
      cwd: nil,
      canModifySourceFiles: false,
      canModifyDerivedFiles: false)
    let use = tool.use(toolUseId: "exec-123", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "execute_command",
        "input": {
          "canModifyDerivedFiles": false,
          "canModifySourceFiles": false,
          "command": "pwd"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "exec-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - with working directory")
  func test_toolUseEncodingDecodingWithCwd() throws {
    let tool = ExecuteCommandTool()
    let input = ExecuteCommandTool.Use.Input(
      command: "git status",
      cwd: "/path/to/project",
      canModifySourceFiles: false,
      canModifyDerivedFiles: true)
    let use = tool.use(toolUseId: "exec-git-456", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "execute_command",
        "input": {
          "canModifyDerivedFiles": true,
          "canModifySourceFiles": false,
          "command": "git status",
          "cwd": "/path/to/project"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "exec-git-456"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - with permissions")
  func test_toolUseEncodingDecodingWithPermissions() throws {
    let tool = ExecuteCommandTool()
    let input = ExecuteCommandTool.Use.Input(
      command: "swift build",
      cwd: "/source",
      canModifySourceFiles: true,
      canModifyDerivedFiles: true)
    let use = tool.use(toolUseId: "exec-build-789", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "execute_command",
        "input": {
          "canModifyDerivedFiles": true,
          "canModifySourceFiles": true,
          "command": "swift build",
          "cwd": "/source"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "exec-build-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
