// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import LLMFoundation
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

  @Test("EnableReasoning parameter set to true for reasoning-capable models")
  func testEnableReasoningTrueForReasoningModels() async throws {
    let requestCompleted = expectation(description: "Request completed")
    let mockServer = MockServer()
    let service = DefaultLLMService(server: mockServer)

    mockServer.onPostRequest = { path, data, _ in
      #expect(path == "sendMessage")
      data.expectToMatch("""
        {
          "messages" : [
            {
              "content" : [
                {
                  "text" : "Hello",
                  "type" : "text"
                }
              ],
              "role" : "user"
            }
          ],
          "model" : "claude-sonnet-4-20250514",
          "enableReasoning": false,
          "provider" : {
            "name" : "anthropic",
            "settings" : { "apiKey" : "anthropic-key" }
          },
          "tools" : [],
          "projectRoot" : "/test"
        }
        """, ignoring: "system")
      requestCompleted.fulfill()
      return okServerResponse
    }

    // Use a model that supports reasoning
    let reasoningModel = LLMModel.claudeSonnet_4_0
    #expect(reasoningModel.canReason == true)

    _ = try await service.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "Hello"))])],
      tools: [],
      model: reasoningModel,
      context: TestChatContext(projectRoot: URL(filePath: "/test"))) { _ in }

    try await fulfillment(of: [requestCompleted])
  }

  @Test("EnableReasoning parameter set to false for non-reasoning models")
  func testEnableReasoningFalseForNonReasoningModels() async throws {
    let requestCompleted = expectation(description: "Request completed")
    let mockServer = MockServer()
    let service = DefaultLLMService(server: mockServer)

    mockServer.onPostRequest = { path, data, _ in
      #expect(path == "sendMessage")
      data.expectToMatch("""
        {
          "messages" : [
            {
              "content" : [
                {
                  "text" : "Hello",
                  "type" : "text"
                }
              ],
              "role" : "user"
            }
          ],
          "model" : "claude-3-5-haiku-latest",
          "enableReasoning": false,
          "provider" : {
            "name" : "anthropic",
            "settings" : { "apiKey" : "anthropic-key" }
          },
          "tools" : [],
          "projectRoot" : "/test"
        }
        """, ignoring: "system")
      requestCompleted.fulfill()
      return okServerResponse
    }

    // Use a model that doesn't support reasoning
    let nonReasoningModel = LLMModel.claudeHaiku_3_5
    #expect(nonReasoningModel.canReason == false)

    _ = try await service.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "Hello"))])],
      tools: [],
      model: nonReasoningModel,
      context: TestChatContext(projectRoot: URL(filePath: "/test"))) { _ in }

    try await fulfillment(of: [requestCompleted])
  }

  @Test("EnableReasoning parameter correctly set for OpenAI reasoning models")
  func testEnableReasoningForOpenAIModels() async throws {
    let requestCompleted = expectation(description: "Request completed")
    let mockServer = MockServer()
    let service = DefaultLLMService(server: mockServer)

    mockServer.onPostRequest = { path, data, _ in
      #expect(path == "sendMessage")
      data.expectToMatch("""
        {
          "messages" : [
            {
              "content" : [
                {
                  "text" : "Hello",
                  "type" : "text"
                }
              ],
              "role" : "user"
            }
          ],
          "model" : "o3",
          "enableReasoning": false,
          "provider" : {
            "name" : "openai",
            "settings" : { "apiKey" : "openai-key" }
          },
          "tools" : [],
          "projectRoot" : "/test"
        }
        """, ignoring: "system")
      requestCompleted.fulfill()
      return okServerResponse
    }

    // Test OpenAI reasoning model
    let o3Model = LLMModel.o3
    #expect(o3Model.canReason == true)

    _ = try await service.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "Hello"))])],
      tools: [],
      model: o3Model,
      context: TestChatContext(projectRoot: URL(filePath: "/test"))) { _ in }

    try await fulfillment(of: [requestCompleted])
  }

  @Test("EnableReasoning parameter correctly set for OpenAI non-reasoning models")
  func testEnableReasoningForNonReasoningOpenAIModels() async throws {
    let requestCompleted = expectation(description: "Request completed")
    let mockServer = MockServer()
    let service = DefaultLLMService(server: mockServer)

    mockServer.onPostRequest = { path, data, _ in
      #expect(path == "sendMessage")
      data.expectToMatch("""
        {
          "messages" : [
            {
              "content" : [
                {
                  "text" : "Hello",
                  "type" : "text"
                }
              ],
              "role" : "user"
            }
          ],
          "model" : "gpt-4o",
          "enableReasoning": false,
          "provider" : {
            "name" : "openai",
            "settings" : { "apiKey" : "openai-key" }
          },
          "tools" : [],
          "projectRoot" : "/test"
        }
        """, ignoring: "system")
      requestCompleted.fulfill()
      return okServerResponse
    }

    // Test OpenAI non-reasoning model
    let gpt4Model = LLMModel.gpt_4o
    #expect(gpt4Model.canReason == false)

    _ = try await service.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "Hello"))])],
      tools: [],
      model: gpt4Model,
      context: TestChatContext(projectRoot: URL(filePath: "/test"))) { _ in }

    try await fulfillment(of: [requestCompleted])
  }
}
