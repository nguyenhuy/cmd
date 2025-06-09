// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import AskFollowUpTool

// MARK: - AskFollowUpToolEncodingTests

struct AskFollowUpToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - basic question")
  func test_toolUseEncodingDecodingBasic() throws {
    let tool = AskFollowUpTool()
    let input = AskFollowUpTool.Use.Input(
      question: "Test question",
      followUp: ["Follow up 1"])
    let use = tool.use(toolUseId: "test-123", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
      {
        "callingTool": "ask_followup",
        "input": {
          "followUp": [
            "Follow up 1"
          ],
          "question": "Test question"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "test-123"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - complex question")
  func test_toolUseEncodingDecodingComplex() throws {
    let tool = AskFollowUpTool()
    let input = AskFollowUpTool.Use.Input(
      question: "Complex question",
      followUp: ["Step 1", "Step 2", "Step 3"])
    let use = tool.use(toolUseId: "complex-456", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
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

  @Test("Tool Use encoding/decoding - empty follow up")
  func test_toolUseEncodingDecodingEmptyFollowUp() throws {
    let tool = AskFollowUpTool()
    let input = AskFollowUpTool.Use.Input(
      question: "Simple question?",
      followUp: [])
    let use = tool.use(toolUseId: "simple-789", input: input, context: toolExecutionContext)

    try testDecodingEncodingWithTool(of: use, tool: tool, """
      {
        "callingTool": "ask_followup",
        "input": {
          "followUp": [

          ],
          "question": "Simple question?"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "simple-789"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)

private func testDecodingEncodingWithTool(
  of value: some Codable,
  tool: any Tool,
  _ json: String)
  throws
{
  // Create decoder with tool plugin
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)
  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  // Create encoder
  let encoder = JSONEncoder()

  // Use the test function with proper decoder/encoder
  try testDecodingEncoding(of: value, json, decoder: decoder, encoder: encoder)
}
