// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import SearchFilesTool

// MARK: - SearchFilesToolEncodingTests

struct SearchFilesToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - basic search")
  func test_toolUseEncodingDecodingBasic() throws {
    let tool = SearchFilesTool()
    let input = SearchFilesTool.Use.Input(
      directoryPath: "/project",
      regex: "FIXME",
      filePattern: nil)
    let use = tool.use(toolUseId: "search-123", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "search_files",
        "input": {
          "directoryPath": "/project",
          "regex": "FIXME"
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "search-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - with file pattern")
  func test_toolUseEncodingDecodingWithPattern() throws {
    let tool = SearchFilesTool()
    let input = SearchFilesTool.Use.Input(
      directoryPath: "/codebase/src",
      regex: "class\\s+\\w+Test",
      filePattern: "*.swift")
    let use = tool.use(toolUseId: "search-pattern-456", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "search_files",
        "input": {
          "directoryPath": "/codebase/src",
          "filePattern": "*.swift",
          "regex": "class\\\\s+\\\\w+Test"
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "search-pattern-456"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - complex regex")
  func test_toolUseEncodingDecodingComplexRegex() throws {
    let tool = SearchFilesTool()
    let input = SearchFilesTool.Use.Input(
      directoryPath: "/workspace/backend",
      regex: "api\\..*\\(",
      filePattern: "*.{py,js}")
    let use = tool.use(toolUseId: "search-structure-789", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "search_files",
        "input": {
          "directoryPath": "/workspace/backend",
          "filePattern": "*.{py,js}",
          "regex": "api\\\\..*\\\\("
        },
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "search-structure-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
