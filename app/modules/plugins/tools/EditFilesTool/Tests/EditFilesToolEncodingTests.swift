// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import JSONFoundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import EditFilesTool

// MARK: - EditFilesToolEncodingTests

struct EditFilesToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - single file edit")
  func test_toolUseEncodingDecodingSingleFile() throws {
    let tool = EditFilesTool(shouldAutoApply: false)

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "/project/README.md",
      isNewFile: false,
      changes: [
        EditFilesTool.Use.Input.FileChange.Change(
          search: "# Old Title",
          replace: "# New Title"),
      ])

    let input = EditFilesTool.Use.Input(files: [fileChange])
    let data = try JSONEncoder().encode(input)
    let use = try tool.use(toolUseId: "edit-123", input: data, isInputComplete: true, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "edit_files",
        "isInputComplete": true,
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "edit-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - new file creation")
  func test_toolUseEncodingDecodingNewFile() throws {
    let tool = EditFilesTool(shouldAutoApply: false)

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "/config/settings.json",
      isNewFile: true,
      changes: [
        EditFilesTool.Use.Input.FileChange.Change(
          search: "",
          replace: "{\"environment\": \"production\"}"),
      ])

    let input = EditFilesTool.Use.Input(files: [fileChange])
    let data = try JSONEncoder().encode(input)
    let use = try tool.use(toolUseId: "edit-new-456", input: data, isInputComplete: true, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "edit_files",
        "isInputComplete": true,
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "edit-new-456"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - multiple files")
  func test_toolUseEncodingDecodingMultipleFiles() throws {
    let tool = EditFilesTool(shouldAutoApply: false)

    let fileChanges = [
      EditFilesTool.Use.Input.FileChange(
        path: "/src/constants.swift",
        isNewFile: false,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "let API_URL = \"dev.example.com\"",
            replace: "let API_URL = \"api.example.com\""),
        ]),
      EditFilesTool.Use.Input.FileChange(
        path: "/tests/NewTest.swift",
        isNewFile: true,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "",
            replace: "import XCTest\n\nclass NewTest: XCTestCase {\n    // Test implementation\n}"),
        ]),
    ]

    let input = EditFilesTool.Use.Input(files: fileChanges)
    let data = try JSONEncoder().encode(input)
    let use = try tool.use(toolUseId: "edit-multi-789", input: data, isInputComplete: true, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "edit_files",
        "isInputComplete": true,
        "status": {
          "status": "pendingApproval"
        },
        "toolUseId": "edit-multi-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
