// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import LSTool

// MARK: - LSToolEncodingTests

enum LSToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding - path only")
    func test_inputEncodingDecodingPathOnly() throws {
      let input = LSTool.Use.Input(
        path: "/project/src",
        recursive: nil)

      try testEncodingDecoding(input, """
        {
          "path": "/project/src"
        }
        """)
    }

    @Test("Input encoding/decoding - with recursive false")
    func test_inputEncodingDecodingNonRecursive() throws {
      let input = LSTool.Use.Input(
        path: "/home/user/documents",
        recursive: false)

      try testEncodingDecoding(input, """
        {
          "path": "/home/user/documents",
          "recursive": false
        }
        """)
    }

    @Test("Input encoding/decoding - with recursive true")
    func test_inputEncodingDecodingRecursive() throws {
      let input = LSTool.Use.Input(
        path: "/workspace/project",
        recursive: true)

      try testEncodingDecoding(input, """
        {
          "path": "/workspace/project",
          "recursive": true
        }
        """)
    }

    @Test("Input encoding/decoding - relative path")
    func test_inputEncodingDecodingRelativePath() throws {
      let input = LSTool.Use.Input(
        path: "./src/components",
        recursive: true)

      try testEncodingDecoding(input, """
        {
          "path": "./src/components",
          "recursive": true
        }
        """)
    }

    @Test("Input encoding/decoding - root path")
    func test_inputEncodingDecodingRootPath() throws {
      let input = LSTool.Use.Input(
        path: "/",
        recursive: false)

      try testEncodingDecoding(input, """
        {
          "path": "/",
          "recursive": false
        }
        """)
    }
  }

  struct OutputFileEncoding {

    // MARK: - Output File Encoding/Decoding Tests

    @Test("Output File encoding/decoding - basic file")
    func test_outputFileEncodingDecoding() throws {
      let file = LSTool.Use.Output.File(
        path: "/project/main.swift",
        attr: "-rw-r--r--",
        size: "1.2K")

      try testEncodingDecoding(file, """
        {
          "path": "/project/main.swift",
          "attr": "-rw-r--r--",
          "size": "1.2K"
        }
        """)
    }

    @Test("Output File encoding/decoding - directory")
    func test_outputFileEncodingDecodingDirectory() throws {
      let file = LSTool.Use.Output.File(
        path: "/project/Sources",
        attr: "drwxr-xr-x",
        size: "4.0K")

      try testEncodingDecoding(file, """
        {
          "path": "/project/Sources",
          "attr": "drwxr-xr-x",
          "size": "4.0K"
        }
        """)
    }

    @Test("Output File encoding/decoding - executable file")
    func test_outputFileEncodingDecodingExecutable() throws {
      let file = LSTool.Use.Output.File(
        path: "/usr/bin/swift",
        attr: "-rwxr-xr-x",
        size: "145M")

      try testEncodingDecoding(file, """
        {
          "path": "/usr/bin/swift",
          "attr": "-rwxr-xr-x",
          "size": "145M"
        }
        """)
    }
  }

  struct OutputEncoding {

    // MARK: - Output Encoding/Decoding Tests

    @Test("Output encoding/decoding - empty directory")
    func test_outputEncodingDecodingEmpty() throws {
      let output = LSTool.Use.Output(
        files: [],
        hasMore: false)

      try testEncodingDecoding(output, """
        {
          "files": [],
          "hasMore": false
        }
        """)
    }

    @Test("Output encoding/decoding - single file")
    func test_outputEncodingDecodingSingleFile() throws {
      let file = LSTool.Use.Output.File(
        path: "/config/settings.json",
        attr: "-rw-r--r--",
        size: "512B")

      let output = LSTool.Use.Output(
        files: [file],
        hasMore: false)

      try testEncodingDecoding(output, """
        {
          "files": [
            {
              "path": "/config/settings.json",
              "attr": "-rw-r--r--",
              "size": "512B"
            }
          ],
          "hasMore": false
        }
        """)
    }

    @Test("Output encoding/decoding - multiple files with hasMore")
    func test_outputEncodingDecodingMultipleFiles() throws {
      let files = [
        LSTool.Use.Output.File(
          path: "/src/main.swift",
          attr: "-rw-r--r--",
          size: "2.3K"),
        LSTool.Use.Output.File(
          path: "/src/utils",
          attr: "drwxr-xr-x",
          size: "4.0K"),
        LSTool.Use.Output.File(
          path: "/tests/MainTests.swift",
          attr: "-rw-r--r--",
          size: "1.8K"),
      ]

      let output = LSTool.Use.Output(
        files: files,
        hasMore: true)

      try testEncodingDecoding(output, """
        {
          "files": [
            {
              "path": "/src/main.swift",
              "attr": "-rw-r--r--",
              "size": "2.3K"
            },
            {
              "path": "/src/utils",
              "attr": "drwxr-xr-x",
              "size": "4.0K"
            },
            {
              "path": "/tests/MainTests.swift",
              "attr": "-rw-r--r--",
              "size": "1.8K"
            }
          ],
          "hasMore": true
        }
        """)
    }
  }

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding - non-recursive")
    func test_toolUseEncodingDecodingNonRecursive() throws {
      let tool = LSTool()
      let input = LSTool.Use.Input(
        path: "/project",
        recursive: false)
      let use = tool.use(toolUseId: "ls-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(LSTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "ls-123")
      #expect(decodedUse.input.path == "/project")
      #expect(decodedUse.input.recursive == false)
    }

    @Test("Tool Use encoding/decoding - recursive")
    func test_toolUseEncodingDecodingRecursive() throws {
      let tool = LSTool()
      let input = LSTool.Use.Input(
        path: "/workspace/src",
        recursive: true)
      let use = tool.use(toolUseId: "ls-recursive-456", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(LSTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "ls-recursive-456")
      #expect(decodedUse.input.path == "/workspace/src")
      #expect(decodedUse.input.recursive == true)
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = LSTool()
      let input = LSTool.Use.Input(
        path: "/home/user/projects",
        recursive: true)
      let use = tool.use(toolUseId: "ls-structure-789", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
        {
          "callingTool": "list_files",
          "input": {
            "path": "/home/user/projects",
            "recursive": true
          },
          "status": {
            "status": "notStarted"
          },
          "toolUseId": "ls-structure-789"
        }
        """)
    }
  }
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = LSTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
