// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import ReadFileTool

// MARK: - ReadFileToolEncodingTests

struct ReadFileToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - path only")
  func test_toolUseEncodingDecodingPathOnly() throws {
    let tool = ReadFileTool()
    let input = ReadFileTool.Use.Input(
      path: "/src/main.swift",
      lineRange: nil)
    let use = tool.use(toolUseId: "read-123", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "read_file",
        "input": {
          "path": "/src/main.swift"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "read-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - with line range")
  func test_toolUseEncodingDecodingWithRange() throws {
    let tool = ReadFileTool()
    let lineRange = ReadFileTool.Use.Input.Range(start: 5, end: 15)
    let input = ReadFileTool.Use.Input(
      path: "/test/file.py",
      lineRange: lineRange)
    let use = tool.use(toolUseId: "read-range-456", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "read_file",
        "input": {
          "lineRange": {
            "end": 15,
            "start": 5
          },
          "path": "/test/file.py"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "read-range-456"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - single line")
  func test_toolUseEncodingDecodingSingleLine() throws {
    let tool = ReadFileTool()
    let lineRange = ReadFileTool.Use.Input.Range(start: 25, end: 25)
    let input = ReadFileTool.Use.Input(
      path: "/config/settings.json",
      lineRange: lineRange)
    let use = tool.use(toolUseId: "read-single-789", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "read_file",
        "input": {
          "lineRange": {
            "end": 25,
            "start": 25
          },
          "path": "/config/settings.json"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "read-single-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
