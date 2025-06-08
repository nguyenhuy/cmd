// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import ReadFileTool

// MARK: - ReadFileToolEncodingTests

enum ReadFileToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding - path only")
    func test_inputEncodingDecodingPathOnly() throws {
      let input = ReadFileTool.Use.Input(
        path: "/path/to/file.swift",
        lineRange: nil)

      try testEncodingDecoding(input, """
        {
          "path": "/path/to/file.swift"
        }
        """)
    }

    @Test("Input encoding/decoding - with line range")
    func test_inputEncodingDecodingWithLineRange() throws {
      let lineRange = ReadFileTool.Use.Input.Range(start: 10, end: 50)
      let input = ReadFileTool.Use.Input(
        path: "/source/main.swift",
        lineRange: lineRange)

      try testEncodingDecoding(input, """
        {
          "path": "/source/main.swift",
          "lineRange": {
            "start": 10,
            "end": 50
          }
        }
        """)
    }

    @Test("Input encoding/decoding - with relative path")
    func test_inputEncodingDecodingRelativePath() throws {
      let input = ReadFileTool.Use.Input(
        path: "src/utils/helper.js",
        lineRange: nil)

      try testEncodingDecoding(input, """
        {
          "path": "src/utils/helper.js"
        }
        """)
    }

    @Test("Input encoding/decoding - with single line range")
    func test_inputEncodingDecodingSingleLine() throws {
      let lineRange = ReadFileTool.Use.Input.Range(start: 25, end: 25)
      let input = ReadFileTool.Use.Input(
        path: "/config/settings.json",
        lineRange: lineRange)

      try testEncodingDecoding(input, """
        {
          "path": "/config/settings.json",
          "lineRange": {
            "start": 25,
            "end": 25
          }
        }
        """)
    }
  }

  struct RangeEncoding {

    // MARK: - Range Encoding/Decoding Tests

    @Test("Range encoding/decoding - normal range")
    func test_rangeEncodingDecodingNormal() throws {
      let range = ReadFileTool.Use.Input.Range(start: 1, end: 100)

      try testEncodingDecoding(range, """
        {
          "start": 1,
          "end": 100
        }
        """)
    }

    @Test("Range encoding/decoding - zero based")
    func test_rangeEncodingDecodingZeroBased() throws {
      let range = ReadFileTool.Use.Input.Range(start: 0, end: 5)

      try testEncodingDecoding(range, """
        {
          "start": 0,
          "end": 5
        }
        """)
    }

    @Test("Range encoding/decoding - large numbers")
    func test_rangeEncodingDecodingLarge() throws {
      let range = ReadFileTool.Use.Input.Range(start: 1000, end: 9999)

      try testEncodingDecoding(range, """
        {
          "start": 1000,
          "end": 9999
        }
        """)
    }
  }

  struct OutputEncoding {

    // MARK: - Output Encoding/Decoding Tests

    @Test("Output encoding/decoding - simple content")
    func test_outputEncodingDecodingSimple() throws {
      let output = ReadFileTool.Use.Output(
        content: "print(\"Hello, World!\")",
        uri: "file:///path/to/hello.swift")

      try testEncodingDecoding(output, """
        {
          "content": "print(\\"Hello, World!\\")",
          "uri": "file:///path/to/hello.swift"
        }
        """)
    }

    @Test("Output encoding/decoding - multiline content")
    func test_outputEncodingDecodingMultiline() throws {
      let content = """
        import Foundation

        func greet(name: String) {
            print("Hello, \\(name)!")
        }

        greet(name: "World")
        """

      let output = ReadFileTool.Use.Output(
        content: content,
        uri: "file:///example/greeting.swift")

      try testEncodingDecoding(output, """
        {
          "content": "import Foundation\\n\\nfunc greet(name: String) {\\n    print(\\"Hello, \\\\(name)!\\")\\n}\\n\\ngreet(name: \\"World\\")",
          "uri": "file:///example/greeting.swift"
        }
        """)
    }

    @Test("Output encoding/decoding - empty content")
    func test_outputEncodingDecodingEmpty() throws {
      let output = ReadFileTool.Use.Output(
        content: "",
        uri: "file:///empty/file.txt")

      try testEncodingDecoding(output, """
        {
          "content": "",
          "uri": "file:///empty/file.txt"
        }
        """)
    }

    @Test("Output encoding/decoding - special characters")
    func test_outputEncodingDecodingSpecialChars() throws {
      let content = """
        // 特殊字符测试 🚀
        let emoji = "🎉"
        let unicode = "你好世界"
        let quotes = "This has \\"quotes\\" and 'apostrophes'"
        """

      let output = ReadFileTool.Use.Output(
        content: content,
        uri: "file:///test/unicode.swift")

      try testEncodingDecoding(output, """
        {
          "content": "// 特殊字符测试 🚀\\nlet emoji = \\"🎉\\"\\nlet unicode = \\"你好世界\\"\\nlet quotes = \\"This has \\\\\\"quotes\\\\\\" and 'apostrophes'\\"",
          "uri": "file:///test/unicode.swift"
        }
        """)
    }
  }

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding - path only")
    func test_toolUseEncodingDecodingPathOnly() throws {
      let tool = ReadFileTool()
      let input = ReadFileTool.Use.Input(
        path: "/src/main.swift",
        lineRange: nil)
      let use = tool.use(toolUseId: "read-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(ReadFileTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "read-123")
      #expect(decodedUse.input.path == "/src/main.swift")
      #expect(decodedUse.input.lineRange == nil)
    }

    @Test("Tool Use encoding/decoding - with line range")
    func test_toolUseEncodingDecodingWithRange() throws {
      let tool = ReadFileTool()
      let lineRange = ReadFileTool.Use.Input.Range(start: 5, end: 15)
      let input = ReadFileTool.Use.Input(
        path: "/test/file.py",
        lineRange: lineRange)
      let use = tool.use(toolUseId: "read-range-456", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(ReadFileTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "read-range-456")
      #expect(decodedUse.input.path == "/test/file.py")
      #expect(decodedUse.input.lineRange?.start == 5)
      #expect(decodedUse.input.lineRange?.end == 15)
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = ReadFileTool()
      let lineRange = ReadFileTool.Use.Input.Range(start: 1, end: 10)
      let input = ReadFileTool.Use.Input(
        path: "/project/source.cpp",
        lineRange: lineRange)
      let use = tool.use(toolUseId: "read-preserve-789", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
        {
          "callingTool": "read_file",
          "input": {
            "lineRange": {
              "end": 10,
              "start": 1
            },
            "path": "/project/source.cpp"
          },
          "status": {
            "status": "notStarted"
          },
          "toolUseId": "read-preserve-789"
        }
        """)
    }
  }
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = ReadFileTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
