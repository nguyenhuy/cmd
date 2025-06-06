// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ServerServiceInterface
import SwiftTesting
import Testing
@testable import LLMService

struct APIParamsEncodingTests {
  @Test("Message.text encoding")
  func testMessageTextEncoding() throws {
    let message = Schema.Message(role: .user, content: [.textMessage(.init(text: "Hello"))])
    try testEncoding(message, """
      {
        "role" : "user",
        "content" : [
          {
            "text" : "Hello",
            "type" : "text"
          }
        ]
      }
      """)
  }

  @Test("Message.toolResult success encoding")
  func testToolResultSuccessEncoding() throws {
    let toolResult = Schema.ToolResultMessage(
      toolUseId: "123",
      toolName: "someTool",
      result: .success([
        "result": .string("Result"),
      ]))
    let message = Schema.Message(role: .tool, content: [.toolResultMessage(toolResult)])

    try testEncoding(message, """
      {        
        "role" : "tool",
        "content" : [
          {
            "type" : "tool_result",
            "result" : {
              "type" : "tool_result_success",
              "success" : {
                "result" : "Result"
              }
            },
            "toolName" : "someTool",
            "toolUseId" : "123"
          }
        ]
      }
      """)
  }

  @Test("Message.toolResult error encoding")
  func testToolResultErrorEncoding() throws {
    let toolResult = Schema.ToolResultMessage(
      toolUseId: "123",
      toolName: "someTool",
      result: .failure("Error occurred"))
    let message = Schema.Message(role: .tool, content: [.toolResultMessage(toolResult)])

    try testEncoding(message, """
      {        
        "role" : "tool",
        "content" : [
          {
            "type" : "tool_result",
            "result" : {
              "type" : "tool_result_failure",
              "failure" : {
                "error" : "Error occurred"
              }
            },
            "toolName" : "someTool",
            "toolUseId" : "123"
          }
        ]
      }
      """)
  }

  @Test("SendMessagesParams encoding")
  func testSendMessagesParamsEncoding() throws {
    let messages: [Schema.Message] = [
      Schema.Message(role: .user, content: [.textMessage(Schema.TextMessage(text: "Hello"))]),
      Schema.Message(role: .assistant, content: [.textMessage(Schema.TextMessage(text: "Hi"))]),
    ]

    let params = Schema.SendMessageRequestParams(
      messages: messages,
      system: "Be helpful",
      projectRoot: "/path/to/workspace",
      tools: [],
      model: "claude-3.5-sonnet",
      enableReasoning: false,
      provider: .init(name: .anthropic, settings: .init()))

    try testEncoding(params, """
      {
        "system" : "Be helpful",
        "tools" : [],
        "model" : "claude-3.5-sonnet",
        "enableReasoning": false,
        "provider" : {
          "name" : "anthropic",
          "settings" : {}
        },
        "projectRoot": "/path/to/workspace",
        "messages" : [
          {
            "role" : "user",
            "content" : [
              {
                "text" : "Hello",
                "type" : "text"
              }
            ]
          },
          {
            "role" : "assistant", 
            "content" : [
              {
                "text" : "Hi",
                "type" : "text"
              }
            ]
          }
        ]
      }
      """)
  }

  @Test("ToolResultParam encoding")
  func testToolResultParamEncoding() throws {
    try testEncoding(Schema.ToolResultMessage(
      toolUseId: "123",
      toolName: "someTool",
      result: .success([:])), """
        {
          "result" : {
            "success" : {

            },
            "type" : "tool_result_success"
          },
          "toolName" : "someTool",
          "toolUseId" : "123",
          "type" : "tool_result"
        }
        """)

    try testEncoding(Schema.ToolResultMessage(
      toolUseId: "123",
      toolName: "someTool",
      result: .success(["it": .string("worked!")])), """
        {
          "result" : {
            "success" : {
              "it" : "worked!"
            },
            "type" : "tool_result_success"
          },
          "toolUseId" : "123",
          "toolName" : "someTool",
          "type" : "tool_result"
        }
        """)
  }
}
