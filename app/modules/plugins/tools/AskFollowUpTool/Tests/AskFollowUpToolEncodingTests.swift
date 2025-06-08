// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import AskFollowUpTool

// MARK: - AskFollowUpToolEncodingTests

enum AskFollowUpToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding round trip")
    func test_inputEncodingDecoding() throws {
      let input = AskFollowUpTool.Use.Input(
        question: "What is the weather?",
        followUp: ["Check temperature", "Check humidity"])

      try testEncodingDecoding(input, """
        {
          "question": "What is the weather?",
          "followUp": [
            "Check temperature",
            "Check humidity"
          ]
        }
        """)
    }

    @Test("Input with empty follow up")
    func test_inputWithEmptyFollowUp() throws {
      let input = AskFollowUpTool.Use.Input(
        question: "Simple question?",
        followUp: [])

      try testEncodingDecoding(input, """
        {
          "question": "Simple question?",
          "followUp": []
        }
        """)
    }

    @Test("Input with special characters")
    func test_inputWithSpecialCharacters() throws {
      let input = AskFollowUpTool.Use.Input(
        question: "What's the \"best\" way to handle [special] characters?",
        followUp: ["Test with unicode: 你好", "Test with emojis: 🚀"])

      try testEncodingDecoding(input, """
        {
          "question": "What's the \\"best\\" way to handle [special] characters?",
          "followUp": [
            "Test with unicode: 你好",
            "Test with emojis: 🚀"
          ]
        }
        """)
    }
  }

  struct OutputEncoding {

    // MARK: - Output Encoding/Decoding Tests

    @Test("Output encoding/decoding round trip")
    func test_outputEncodingDecoding() throws {
      let output = AskFollowUpTool.Use.Output(
        response: "The weather is sunny today with a temperature of 75°F.")

      try testEncodingDecoding(output, """
        {
          "response": "The weather is sunny today with a temperature of 75°F."
        }
        """)
    }

    @Test("Output with empty response")
    func test_outputWithEmptyResponse() throws {
      let output = AskFollowUpTool.Use.Output(response: "")

      try testEncodingDecoding(output, """
        {
          "response": ""
        }
        """)
    }

    @Test("Output with multiline response")
    func test_outputWithMultilineResponse() throws {
      let output = AskFollowUpTool.Use.Output(
        response: """
          Line 1: Weather information
          Line 2: Temperature details
          Line 3: Additional notes
          """)

      try testEncodingDecoding(output, """
        {
          "response": "Line 1: Weather information\\nLine 2: Temperature details\\nLine 3: Additional notes"
        }
        """)
    }
  }

  // MARK: - Tool Use Encoding/Decoding Tests

  struct ToolUseEncoding {
    @Test("Tool Use encoding/decoding round trip")
    func test_toolUseEncodingDecoding() throws {
      let tool = AskFollowUpTool()
      let input = AskFollowUpTool.Use.Input(
        question: "Test question",
        followUp: ["Follow up 1"])
      let use = tool.use(toolUseId: "test-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(AskFollowUpTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "test-123")
      #expect(decodedUse.input.question == "Test question")
      #expect(decodedUse.input.followUp == ["Follow up 1"])
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = AskFollowUpTool()
      let input = AskFollowUpTool.Use.Input(
        question: "Complex question",
        followUp: ["Step 1", "Step 2", "Step 3"])
      let use = tool.use(toolUseId: "complex-456", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      encodedData.expectToMatch("""
        {
          "callingTool": "ask_followup",
          "input": {
            "followUp": [
              "Step 1",
              "Step 2", 
              "Step 3"
            ],
            "question": "Complex question"
          },
          "status": {
            "status": "notStarted"
          },
          "toolUseId": "complex-456"
        }
        """)
    }
  }
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = AskFollowUpTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
