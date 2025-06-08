// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import SearchFilesTool

// MARK: - SearchFilesToolEncodingTests

enum SearchFilesToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding - basic search")
    func test_inputEncodingDecodingBasic() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/project/src",
        regex: "TODO",
        filePattern: nil)

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/project/src",
          "regex": "TODO"
        }
        """)
    }

    @Test("Input encoding/decoding - with file pattern")
    func test_inputEncodingDecodingWithPattern() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/workspace",
        regex: "function\\s+\\w+",
        filePattern: "*.swift")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/workspace",
          "regex": "function\\\\s+\\\\w+",
          "filePattern": "*.swift"
        }
        """)
    }

    @Test("Input encoding/decoding - complex regex")
    func test_inputEncodingDecodingComplexRegex() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/src",
        regex: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b",
        filePattern: "*.{js,ts,jsx,tsx}")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/src",
          "regex": "\\\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Z|a-z]{2,}\\\\b",
          "filePattern": "*.{js,ts,jsx,tsx}"
        }
        """)
    }

    @Test("Input encoding/decoding - relative path")
    func test_inputEncodingDecodingRelativePath() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "./components",
        regex: "import.*React",
        filePattern: "*.tsx")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "./components",
          "regex": "import.*React",
          "filePattern": "*.tsx"
        }
        """)
    }

    @Test("Input encoding/decoding - special characters in regex")
    func test_inputEncodingDecodingSpecialChars() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/logs",
        regex: "\\[ERROR\\].*\\d{4}-\\d{2}-\\d{2}",
        filePattern: "*.log")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/logs",
          "regex": "\\\\[ERROR\\\\].*\\\\d{4}-\\\\d{2}-\\\\d{2}",
          "filePattern": "*.log"
        }
        """)
    }

    @Test("Input encoding/decoding - empty regex")
    func test_inputEncodingDecodingEmptyRegex() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/project",
        regex: "",
        filePattern: "*.txt")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/project",
          "regex": "",
          "filePattern": "*.txt"
        }
        """)
    }

    @Test("Input encoding/decoding - unicode in regex")
    func test_inputEncodingDecodingUnicode() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/docs",
        regex: "测试|テスト|🚀",
        filePattern: "*.md")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/docs",
          "regex": "测试|テスト|🚀",
          "filePattern": "*.md"
        }
        """)
    }

    @Test("Input encoding/decoding - very long file pattern")
    func test_inputEncodingDecodingLongPattern() throws {
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/complex/project",
        regex: "import",
        filePattern: "*.{js,jsx,ts,tsx,vue,svelte,py,rb,php,java,kt,swift,rs,go,c,cpp,h,hpp}")

      try testEncodingDecoding(input, """
        {
          "directoryPath": "/complex/project",
          "regex": "import",
          "filePattern": "*.{js,jsx,ts,tsx,vue,svelte,py,rb,php,java,kt,swift,rs,go,c,cpp,h,hpp}"
        }
        """)
    }
  }

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding - basic search")
    func test_toolUseEncodingDecodingBasic() throws {
      let tool = SearchFilesTool()
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/project",
        regex: "FIXME",
        filePattern: nil)
      let use = tool.use(toolUseId: "search-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(SearchFilesTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "search-123")
      #expect(decodedUse.input.directoryPath == "/project")
      #expect(decodedUse.input.regex == "FIXME")
      #expect(decodedUse.input.filePattern == nil)
    }

    @Test("Tool Use encoding/decoding - with file pattern")
    func test_toolUseEncodingDecodingWithPattern() throws {
      let tool = SearchFilesTool()
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/codebase/src",
        regex: "class\\s+\\w+Test",
        filePattern: "*.swift")
      let use = tool.use(toolUseId: "search-pattern-456", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(SearchFilesTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "search-pattern-456")
      #expect(decodedUse.input.directoryPath == "/codebase/src")
      #expect(decodedUse.input.regex == "class\\s+\\w+Test")
      #expect(decodedUse.input.filePattern == "*.swift")
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = SearchFilesTool()
      let input = SearchFilesTool.Use.Input(
        directoryPath: "/workspace/backend",
        regex: "api\\..*\\(",
        filePattern: "*.{py,js}")
      let use = tool.use(toolUseId: "search-structure-789", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
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
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = SearchFilesTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
