// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import LLMServiceInterface
import ServerServiceInterface
import SettingsServiceInterface
import SwiftTesting
import Testing
import ToolFoundation

@testable import LLMService

// MARK: - SendMessageTests

final class SendMessageTests {
  @Test("SendMessage receives text chunks")
  func test_sendMessage() async throws {
    let chunksReceived = expectation(description: "All chunk received")
    let messagesUpdatesReceived = expectation(description: "All messages update received")
    let firstMessageUpdatesReceived = expectation(description: "All updates for the first message received")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      sendChunk?("""
        {
          "type": "text_delta",
          "text": "hi"
        }
        """.utf8Data)
      sendChunk?("""
        {
          "type": "text_delta",
          "text": " what can I do?"
        }
        """.utf8Data)
      return okServerResponse
    }
    let updatingMessages = try await sut.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [])

    var messagesUpdateCount = 0
    var firstMessageUpdateCount = 0
    var contentUpdateCount = 0
    Task {
      for await messages in updatingMessages.updates {
        messagesUpdateCount += 1
        if messagesUpdateCount == 1 {
          // First update has one message
          #expect(messages.count == 1)

          let updatingMessage = try #require(messages.first)

          for await message in updatingMessage.updates {
            firstMessageUpdateCount += 1
            if firstMessageUpdateCount == 1 {
              // First update has one piece of text content
              #expect(message.content.count == 1)
              let updatingTextContent = try #require(message.content.first?.asText)

              for await textContent in updatingTextContent.updates {
                contentUpdateCount += 1
                if contentUpdateCount == 1 {
                  #expect(textContent.content == "hi what can I do?")
                  #expect(textContent.deltas == ["hi", " what can I do?"])
                }
              }
              chunksReceived.fulfill()
            }
          }
          firstMessageUpdatesReceived.fulfill()
        }
      }
      messagesUpdatesReceived.fulfill()
    }

    try await fulfillment(of: [messagesUpdatesReceived, firstMessageUpdatesReceived, chunksReceived])
    #expect(messagesUpdateCount == 1)
    #expect(firstMessageUpdateCount == 1)
    #expect(contentUpdateCount == 1)
  }

  @Test("SendMessage with long message history")
  func test_sendMessage_withLongMessageHistory() async throws {
    let requestResponded = expectation(description: "The request was responded to")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      sendChunk?("""
        {
          "type": "text_delta",
          "text": "sure"
        }
        """.utf8Data)
      requestResponded.fulfill()
      return okServerResponse
    }
    let messages = try await sut.sendMessage(
      messageHistory: [
        .init(role: .user, content: [.textMessage(.init(text: "hello"))]),
        .init(role: .user, content: [.textMessage(.init(text: "sup?"))]),
        .init(role: .user, content: [.textMessage(.init(text: "can you help me?"))]),
        .init(role: .assistant, content: [.textMessage(.init(text: "sure"))]),
        .init(role: .user, content: [.textMessage(.init(text: "I need coffee"))]),
      ],
      tools: []).lastValue

    #expect(messages.count == 1)
    let firstMessage = try await (#require(messages.first)).lastValue
    let firstMessageContent = firstMessage.content
    #expect(firstMessageContent.count == 1)
    let textContent = try await (#require(firstMessageContent.first?.asText)).lastValue
    #expect(textContent.content == "sure")

    try await fulfillment(of: [requestResponded])
  }

  @Test("SendMessage with tool use")
  func test_sendMessage_withToolUse() async throws {
    let requestResponded = expectation(description: "The request was responded to")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)

    let requestCount = Atomic(0)
    server.onPostRequest = { _, data, sendChunk in
      if requestCount.increment() == 1 {
        sendChunk?("""
          {
            "type": "text_delta",
            "text": "hi"
          }
          """.utf8Data)
        sendChunk?("""
          {
            "type": "tool_call",
            "toolName": "TestTool",
            "input": {},
            "toolUseId": "123"
          }
          """.utf8Data)
        return okServerResponse
      } else {
        data.expectToMatch(
          """
          {
            "messages":[
              {"role":"user","content":[{"type":"text","text":"hello"}]},
              {"role":"assistant","content":[
                {"type":"text","text":"hi"},
                {"type":"tool_call","toolUseId":"123","toolName":"TestTool","input":{}}
              ]},
              {"role":"tool","content":[{"toolUseId":"123","toolName":"TestTool","type":"tool_result","result":{"type":"tool_result_success","success":"test_result"}}]}
            ],
            "model" : "claude-sonnet-4-20250514",
            "provider" : {
              "name" : "anthropic",
              "settings" : { "apiKey" : "anthropic-key" }
            },
            "tools":[{"inputSchema":{},"name":"TestTool","description":"tool for testing"}],
            "projectRoot" : "/path/to/root"
          }
          """,
          ignoring: "system")
        sendChunk?("""
          {
            "type": "text_delta",
            "text": "got it!"
          }
          """.utf8Data)
        requestResponded.fulfill()
        return okServerResponse
      }
    }

    let messages = try await sut.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestTool<EmptyObject, String>(output: "test_result")]).lastValue
    #expect(messages.count == 2)

    let firstMessage = try await (#require(messages.first)).lastValue
    let firstMessageContent = firstMessage.content
    #expect(firstMessageContent.count == 2)
    #expect(firstMessageContent.first?.asText?.content == "hi")
    #expect(firstMessageContent.last?.asToolUseRequest != nil)

    let secondMessage = try await (#require(messages.last)).lastValue
    let secondMessageContent = secondMessage.content
    #expect(secondMessageContent.count == 1)
    #expect(secondMessageContent.first?.asText?.content == "got it!")

    try await fulfillment(of: [requestResponded])
  }

  @Test("SendMessage with failed tool use")
  func test_sendMessage_withFailedToolUse() async throws {
    let requestResponded = expectation(description: "The request was responded to")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)

    let requestCount = Atomic(0)
    server.onPostRequest = { _, data, sendChunk in
      if requestCount.increment() == 1 {
        sendChunk?("""
          {
            "type": "tool_call",
            "toolName": "UnknownTool",
            "input": {},
            "toolUseId": "123"
          }
          """.utf8Data)
        return okServerResponse
      } else {
        data.expectToMatch(
          """
          {
            "messages":[
              {"role":"user","content":[{"type":"text","text":"hello"}]},
              {"role":"assistant","content":[
                {"type":"tool_call","toolName":"UnknownTool","toolUseId":"123","input":{}}
              ]},
              {"role":"tool","content":[{"toolUseId":"123","toolName":"UnknownTool","type":"tool_result","result":{"type":"tool_result_failure","failure":"Missing tool UnknownTool"}}]}
            ],
            "model" : "claude-sonnet-4-20250514",
            "provider" : {
              "name" : "anthropic",
              "settings" : { "apiKey" : "anthropic-key" }
            },
            "tools":[{"inputSchema":{},"name":"TestTool","description":"tool for testing"}],
            "projectRoot" : "/path/to/root"
          }
          """,
          ignoring: "system")
        sendChunk?("""
          {
            "type": "text_delta",
            "text": "Let me fix this"
          }
          """.utf8Data)
        requestResponded.fulfill()
        return okServerResponse
      }
    }

    let messages = try await sut.sendMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestTool<EmptyObject, String>(output: "test_result")]).lastValue
    #expect(messages.count == 2)

    let firstMessage = try await (#require(messages.first)).lastValue
    let firstMessageContent = firstMessage.content
    #expect(firstMessageContent.count == 1)
    #expect(firstMessageContent.first?.asToolUseRequest != nil)

    let secondMessage = try await (#require(messages.last)).lastValue
    let secondMessageContent = secondMessage.content
    #expect(secondMessageContent.count == 1)
    #expect(secondMessageContent.first?.asText?.content == "Let me fix this")

    try await fulfillment(of: [requestResponded])
  }

  @Test("SendMessage fails with CancellationError when cancelled")
  func test_sendMessage_isCancelled() async throws {
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    let requestStarted = expectation(description: "Request started")
    let requestCancelled = expectation(description: "Request cancelled")
    let updateStreamFinished = expectation(description: "Update stream finished")

    server.onPostRequest = { _, _, _ in
      requestStarted.fulfill()

      try await fulfillment(of: requestCancelled)
      // This will be ignored by the ServerMock as we've already returned a cancellation error.
      return okServerResponse
    }

    let task = Task {
      try await sut.sendMessage(
        messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
        tools: [],
        model: .claudeSonnet_4_0,
        context: TestChatContext(projectRoot: URL(filePath: "/path/to/root")),
        handleUpdateStream: { updateStream in
          Task {
            _ = await updateStream.lastValue
            updateStreamFinished.fulfill()
          }
        })
    }

    // Wait for request to start then cancel
    try await fulfillment(of: requestStarted)
    task.cancel()
    requestCancelled.fulfill()

    try await fulfillment(of: updateStreamFinished)
    do {
      _ = try await task.value
      Issue.record("Expected task to throw cancellation error")
    } catch is CancellationError {
      // Expected cancellation
    }
  }

  @Test("SendMessage stops streaming when cancelled")
  func test_sendMessage_stopsStreamingWhenCancelled() async throws {
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    let requestStarted = expectation(description: "Request started")
    let requestCancelled = expectation(description: "Request cancelled")
    let updateStreamFinished = expectation(description: "Update stream finished")

    server.onPostRequest = { _, _, sendChunk in
      requestStarted.fulfill()

      try await fulfillment(of: requestCancelled)

      // While we expect URLSession to not send any partial response after the request is cancelled,
      // we still validate that our API layer would stop the streaming and not fail if that was to happen.
      sendChunk?("""
        {
          "type": "text_delta",
          "text": "hi"
        }
        """.utf8Data)

      // This will be ignored by the ServerMock as we've already returned a cancellation error.
      return okServerResponse
    }

    let task = Task {
      try await sut.sendMessage(
        messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
        tools: [],
        model: .claudeSonnet_4_0,
        context: TestChatContext(projectRoot: URL(filePath: "/path/to/root")),
        handleUpdateStream: { updateStream in
          Task {
            let messages = await updateStream.lastValue
            #expect(messages.count == 1)
            #expect(messages.first?.content.count == 0)
            updateStreamFinished.fulfill()
          }
        })
    }

    // Wait for request to start then cancel
    try await fulfillment(of: [requestStarted])
    task.cancel()
    requestCancelled.fulfill()

    try await fulfillment(of: updateStreamFinished)
    do {
      _ = try await task.value
      Issue.record("Expected task to throw cancellation error")
    } catch is CancellationError {
      // Expected cancellation
    }
  }

  @Test("SendMessage fails if API provider is not configured")
  func test_sendMessage_failsWithNoAPIProvider() async throws {
    let sut = DefaultLLMService(settingsService: MockSettingsService())
    do {
      _ = try await sut.sendMessage(
        messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
        model: .claudeSonnet_4_0,
        context: TestChatContext(projectRoot: URL(filePath: "/path/to/root"))) { _ in }
      Issue.record("Expected sendMessage to throw error")
    } catch {
      #expect(error.localizedDescription == "Anthropic API not configured")
    }
  }
}
