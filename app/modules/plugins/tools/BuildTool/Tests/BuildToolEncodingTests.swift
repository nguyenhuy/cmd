// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
import XcodeControllerServiceInterface
@testable import BuildTool

// MARK: - BuildToolEncodingTests

enum BuildToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding - test build")
    func test_inputEncodingDecodingTest() throws {
      let input = BuildTool.Use.Input(for: .test)

      try testEncodingDecoding(input, """
        {
          "for": "test"
        }
        """)
    }

    @Test("Input encoding/decoding - run build")
    func test_inputEncodingDecodingRun() throws {
      let input = BuildTool.Use.Input(for: .run)

      try testEncodingDecoding(input, """
        {
          "for": "run"
        }
        """)
    }
  }

  struct OutputEncoding {

    // MARK: - Output Encoding/Decoding Tests

    @Test("Output encoding/decoding - successful build")
    func test_outputEncodingDecodingSuccess() throws {
      let buildMessage = BuildMessage(
        type: .note,
        message: "Build completed successfully",
        location: BuildLocation(
          file: "/path/to/file.swift",
          line: 42,
          column: 10))

      let buildSection = BuildSection(
        title: "Build Target",
        messages: [buildMessage],
        isSuccess: true)

      let output = BuildTool.Use.Output(
        buildResult: buildSection,
        isSuccess: true)

      try testEncodingDecoding(output, """
        {
          "buildResult": {
            "title": "Build Target",
            "messages": [
              {
                "type": "note",
                "message": "Build completed successfully",
                "location": {
                  "file": "/path/to/file.swift",
                  "line": 42,
                  "column": 10
                }
              }
            ],
            "isSuccess": true
          },
          "isSuccess": true
        }
        """)
    }

    @Test("Output encoding/decoding - failed build")
    func test_outputEncodingDecodingFailure() throws {
      let errorMessage = BuildMessage(
        type: .error,
        message: "Syntax error: Expected ';' after expression",
        location: BuildLocation(
          file: "/path/to/error.swift",
          line: 15,
          column: 23))

      let buildSection = BuildSection(
        title: "Compile Swift Files",
        messages: [errorMessage],
        isSuccess: false)

      let output = BuildTool.Use.Output(
        buildResult: buildSection,
        isSuccess: false)

      try testEncodingDecoding(output, """
        {
          "buildResult": {
            "title": "Compile Swift Files",
            "messages": [
              {
                "type": "error",
                "message": "Syntax error: Expected ';' after expression",
                "location": {
                  "file": "/path/to/error.swift",
                  "line": 15,
                  "column": 23
                }
              }
            ],
            "isSuccess": false
          },
          "isSuccess": false
        }
        """)
    }

    @Test("Output encoding/decoding - empty build result")
    func test_outputEncodingDecodingEmpty() throws {
      let buildSection = BuildSection(
        title: "No Operations",
        messages: [],
        isSuccess: true)

      let output = BuildTool.Use.Output(
        buildResult: buildSection,
        isSuccess: true)

      try testEncodingDecoding(output, """
        {
          "buildResult": {
            "title": "No Operations",
            "messages": [],
            "isSuccess": true
          },
          "isSuccess": true
        }
        """)
    }
  }

  struct TypeEncoding {

    // MARK: - BuildType Encoding/Decoding Tests

    @Test("BuildType encoding/decoding - all cases")
    func test_buildTypeEncodingDecoding() throws {
      try testEncodingDecoding(BuildType.test, """
        "test"
        """)

      try testEncodingDecoding(BuildType.run, """
        "run"
        """)
    }

    // MARK: - BuildMessage Type Encoding/Decoding Tests

    @Test("BuildMessage type encoding/decoding - all cases")
    func test_buildMessageTypeEncodingDecoding() throws {
      try testEncodingDecoding(BuildMessage.MessageType.error, """
        "error"
        """)

      try testEncodingDecoding(BuildMessage.MessageType.warning, """
        "warning"
        """)

      try testEncodingDecoding(BuildMessage.MessageType.note, """
        "note"
        """)
    }
  }

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding - test build")
    func test_toolUseEncodingDecodingTest() throws {
      let tool = BuildTool()
      let input = BuildTool.Use.Input(for: .test)
      let use = tool.use(toolUseId: "build-test-789", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(BuildTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "build-test-789")
      #expect(decodedUse.input.for == .test)
    }

    @Test("Tool Use encoding/decoding - run build")
    func test_toolUseEncodingDecodingRun() throws {
      let tool = BuildTool()
      let input = BuildTool.Use.Input(for: .run)
      let use = tool.use(toolUseId: "build-run-101", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(BuildTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "build-run-101")
      #expect(decodedUse.input.for == .run)
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = BuildTool()
      let input = BuildTool.Use.Input(for: .test)
      let use = tool.use(toolUseId: "build-fields-test", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
        {
          "callingTool": "build",
          "input": {
            "for": "test"
          },
          "status": {
            "status": "notStarted"
          },
          "toolUseId": "build-fields-test"
        }
        """)
    }
  }
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = BuildTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
