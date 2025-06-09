// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "list_files",
        "input": {
          "path": "/project",
          "recursive": false
        },
        "status": {
          "status": "notStarted"
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

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "list_files",
        "input": {
          "path": "/workspace/src",
          "recursive": true
        },
        "status": {
          "status": "notStarted"
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

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "list_files",
        "input": {
          "path": "/home/user/projects"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "ls-structure-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
