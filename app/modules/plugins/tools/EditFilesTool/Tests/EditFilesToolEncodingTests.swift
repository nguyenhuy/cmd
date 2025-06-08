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

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding round trip")
    func test_toolUseEncodingDecoding() throws {
      let tool = EditFilesTool()

      let fileChange = EditFilesTool.Use.Input.FileChange(
        path: "/project/README.md",
        isNewFile: false,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "# Old Title",
            replace: "# New Title"),
        ])

      let input = EditFilesTool.Use.Input(files: [fileChange])
      let use = tool.use(toolUseId: "edit-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(EditFilesTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "edit-123")
      #expect(decodedUse.input.files.count == 1)
      #expect(decodedUse.input.files.first?.path == "/project/README.md")
      #expect(decodedUse.input.files.first?.isNewFile == false)
      #expect(decodedUse.input.files.first?.changes.count == 1)
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = EditFilesTool()

      let fileChange = EditFilesTool.Use.Input.FileChange(
        path: "/config/settings.json",
        isNewFile: true,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "",
            replace: "{\\"environment\ \ ": \\"production\ \ "}"),
        ])

      let input = EditFilesTool.Use.Input(files: [fileChange])
      let use = tool.use(toolUseId: "edit-structure-456", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
        {
          "callingTool": "edit_files",
          "isInputComplete": true,
          "status": {
            "status": "pendingApproval"
          },
          "toolUseId": "edit-structure-456"
        }
        """, ignoring: ["context", "inputData"])
    }
  }

  // MARK: - Change Encoding/Decoding Tests

  @Test("Change encoding/decoding - basic search and replace")
  func test_changeEncodingDecodingBasic() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: "old text",
      replace: "new text")

    try testEncodingDecoding(change, """
      {
        "search": "old text",
        "replace": "new text"
      }
      """)
  }

  @Test("Change encoding/decoding - multiline text")
  func test_changeEncodingDecodingMultiline() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: """
        func oldFunction() {
            return "old"
        }
        """,
      replace: """
        func newFunction() {
            return "new"
        }
        """)

    try testEncodingDecoding(change, """
      {
        "search": "func oldFunction() {\\n    return \\"old\\"\\n}",
        "replace": "func newFunction() {\\n    return \\"new\\"\\n}"
      }
      """)
  }

  @Test("Change encoding/decoding - special characters")
  func test_changeEncodingDecodingSpecialChars() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: "let regex = /\\w+\\s*=\\s*[\"']([^\"']+)[\"']/g",
      replace: "const pattern = /\\w+\\s*=\\s*[\"']([^\"']+)[\"']/gi")

    try testEncodingDecoding(change, """
      {
        "search": "let regex = /\\\\w+\\\\s*=\\\\s*[\\\"']([^\\\"']+)[\\\"']/g",
        "replace": "const pattern = /\\\\w+\\\\s*=\\\\s*[\\\"']([^\\\"']+)[\\\"']/gi"
      }
      """)
  }

  @Test("Change encoding/decoding - empty strings")
  func test_changeEncodingDecodingEmpty() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: "",
      replace: "")

    try testEncodingDecoding(change, """
      {
        "search": "",
        "replace": ""
      }
      """)
  }

  // MARK: - FileChange Encoding/Decoding Tests

  @Test("FileChange encoding/decoding - basic file change")
  func test_fileChangeEncodingDecodingBasic() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: "TODO: implement",
      replace: "// Implementation completed")

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "/project/src/main.swift",
      isNewFile: nil,
      changes: [change])

    try testEncodingDecoding(fileChange, """
      {
        "path": "/project/src/main.swift",
        "changes": [
          {
            "search": "TODO: implement",
            "replace": "// Implementation completed"
          }
        ]
      }
      """)
  }

  @Test("FileChange encoding/decoding - new file")
  func test_fileChangeEncodingDecodingNewFile() throws {
    let changes = [
      EditFilesTool.Use.Input.FileChange.Change(
        search: "",
        replace: "import Foundation\\n\\nclass NewClass {\\n    // Implementation\\n}"),
    ]

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "/project/src/NewClass.swift",
      isNewFile: true,
      changes: changes)

    try testEncodingDecoding(fileChange, """
      {
        "path": "/project/src/NewClass.swift",
        "isNewFile": true,
        "changes": [
          {
            "search": "",
            "replace": "import Foundation\\\\n\\\\nclass NewClass {\\\\n    // Implementation\\\\n}"
          }
        ]
      }
      """)
  }

  @Test("FileChange encoding/decoding - existing file")
  func test_fileChangeEncodingDecodingExistingFile() throws {
    let changes = [
      EditFilesTool.Use.Input.FileChange.Change(
        search: "private func helper()",
        replace: "public func helper()"),
      EditFilesTool.Use.Input.FileChange.Change(
        search: "// FIXME:",
        replace: "// TODO:"),
    ]

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "./src/Helper.swift",
      isNewFile: false,
      changes: changes)

    try testEncodingDecoding(fileChange, """
      {
        "path": "./src/Helper.swift",
        "isNewFile": false,
        "changes": [
          {
            "search": "private func helper()",
            "replace": "public func helper()"
          },
          {
            "search": "// FIXME:",
            "replace": "// TODO:"
          }
        ]
      }
      """)
  }

  @Test("FileChange encoding/decoding - multiple changes")
  func test_fileChangeEncodingDecodingMultipleChanges() throws {
    let changes = [
      EditFilesTool.Use.Input.FileChange.Change(
        search: "var count = 0",
        replace: "var count = 10"),
      EditFilesTool.Use.Input.FileChange.Change(
        search: "print(\\"Hello\ \ ")",
        replace: "print(\\"Hello, World!\ \ ")"),
      EditFilesTool.Use.Input.FileChange.Change(
        search: "// Old comment",
        replace: "// New comment with more details"),
    ]

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "/app/main.swift",
      isNewFile: nil,
      changes: changes)

    try testEncodingDecoding(fileChange, """
      {
        "path": "/app/main.swift",
        "changes": [
          {
            "search": "var count = 0",
            "replace": "var count = 10"
          },
          {
            "search": "print(\\"Hello\\")",
            "replace": "print(\\"Hello, World!\\")"
          },
          {
            "search": "// Old comment",
            "replace": "// New comment with more details"
          }
        ]
      }
      """)
  }

  // MARK: - Input Encoding/Decoding Tests

  @Test("Input encoding/decoding - single file")
  func test_inputEncodingDecodingSingleFile() throws {
    let change = EditFilesTool.Use.Input.FileChange.Change(
      search: "version = \\"1.0.0\ \ "",
      replace: "version = \\"2.0.0\ \ "")

    let fileChange = EditFilesTool.Use.Input.FileChange(
      path: "package.json",
      isNewFile: false,
      changes: [change])

    let input = EditFilesTool.Use.Input(files: [fileChange])

    try testEncodingDecoding(input, """
      {
        "files": [
          {
            "path": "package.json",
            "isNewFile": false,
            "changes": [
              {
                "search": "version = \\"1.0.0\\"",
                "replace": "version = \\"2.0.0\\""
              }
            ]
          }
        ]
      }
      """)
  }

  @Test("Input encoding/decoding - multiple files")
  func test_inputEncodingDecodingMultipleFiles() throws {
    let fileChanges = [
      EditFilesTool.Use.Input.FileChange(
        path: "/src/constants.swift",
        isNewFile: false,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "let API_URL = \\"dev.example.com\ \ "",
            replace: "let API_URL = \\"api.example.com\ \ ""),
        ]),
      EditFilesTool.Use.Input.FileChange(
        path: "/tests/NewTest.swift",
        isNewFile: true,
        changes: [
          EditFilesTool.Use.Input.FileChange.Change(
            search: "",
            replace: "import XCTest\\n\\nclass NewTest: XCTestCase {\\n    // Test implementation\\n}"),
        ]),
    ]

    let input = EditFilesTool.Use.Input(files: fileChanges)

    try testEncodingDecoding(input, """
      {
        "files": [
          {
            "path": "/src/constants.swift",
            "isNewFile": false,
            "changes": [
              {
                "search": "let API_URL = \\"dev.example.com\\"",
                "replace": "let API_URL = \\"api.example.com\\""
              }
            ]
          },
          {
            "path": "/tests/NewTest.swift",
            "isNewFile": true,
            "changes": [
              {
                "search": "",
                "replace": "import XCTest\\\\n\\\\nclass NewTest: XCTestCase {\\\\n    // Test implementation\\\\n}"
              }
            ]
          }
        ]
      }
      """)
  }

  @Test("Input encoding/decoding - empty files array")
  func test_inputEncodingDecodingEmpty() throws {
    let input = EditFilesTool.Use.Input(files: [])

    try testEncodingDecoding(input, """
      {
        "files": []
      }
      """)
  }

  // MARK: - Output Encoding/Decoding Tests

  @Test("Output encoding/decoding - simple result")
  func test_outputEncodingDecodingSimple() throws {
    let result = JSON.object([
      "success": .bool(true),
      "message": .string("Files updated successfully"),
    ])

    let output = EditFilesTool.Use.Output(result: result)

    try testEncodingDecoding(output, """
      {
        "result": {
          "success": true,
          "message": "Files updated successfully"
        }
      }
      """)
  }

  @Test("Output encoding/decoding - complex result")
  func test_outputEncodingDecodingComplex() throws {
    let result = JSON.object([
      "filesModified": .array([
        .string("/src/main.swift"),
        .string("/src/helper.swift"),
      ]),
      "filesCreated": .array([
        .string("/tests/NewTest.swift"),
      ]),
      "totalChanges": .number(5),
      "warnings": .array([]),
      "metadata": .object([
        "timestamp": .string("2024-01-15T10:30:00Z"),
        "editor": .string("EditFilesTool"),
        "backup": .bool(true),
      ]),
    ])

    let output = EditFilesTool.Use.Output(result: result)

    try testEncodingDecoding(output, """
      {
        "result": {
          "filesModified": [
            "/src/main.swift",
            "/src/helper.swift"
          ],
          "filesCreated": [
            "/tests/NewTest.swift"
          ],
          "totalChanges": 5,
          "warnings": [],
          "metadata": {
            "timestamp": "2024-01-15T10:30:00Z",
            "editor": "EditFilesTool",
            "backup": true
          }
        }
      }
      """)
  }

}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = EditFilesTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
