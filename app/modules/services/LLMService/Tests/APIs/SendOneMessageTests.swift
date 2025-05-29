// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import SwiftTesting
import Testing

import AppFoundation
import LLMServiceInterface
import ServerServiceInterface

@testable import LLMService

final class SendOneMessageTests {

  @Test("SendOneMessage sends correct payload")
  func test_sendOneMessage_sendsCorrectPayload() async throws {
    let requestCompleted = expectation(description: "The request completed")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { path, data, _ in
      #expect(path == "sendMessage")
      data.expectToMatch("""
        {
          "messages" : [
            {
              "content" : [
                {
                  "text" : "hello",
                  "type" : "text"
                }
              ],
              "role" : "user"
            }
          ],
          "model" : "claude-sonnet-4-20250514",
            "provider" : {
              "name" : "anthropic",
              "settings" : { "apiKey" : "anthropic-key" }
            },
          "tools" : [],
          "projectRoot" : "/path/to/root"
        }
        """, ignoring: "system")
      requestCompleted.fulfill()
      return okServerResponse
    }
    _ = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [])

    try await fulfillment(of: [requestCompleted])
  }

  @Test("SendOneMessage receives text chunks")
  func test_sendOneMessage() async throws {
    let initialStreamExpectationValidated = expectation(description: "initial stream expectation validated")
    let chunksReceived = expectation(description: "All chunk received")
    let messageUpdatesReceived = expectation(description: "All message update received")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      // Wait here to avoid concurrency issues that would make the test flaky.
      try await fulfillment(of: initialStreamExpectationValidated)
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
    let updatingMessage = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [])
    #expect(updatingMessage.content.count == 0)
    initialStreamExpectationValidated.fulfill()

    var messageUpdateCount = 0
    var contentUpdateCount = 0
    Task {
      for await message in updatingMessage.updates {
        messageUpdateCount += 1
        if messageUpdateCount == 1 {
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
      messageUpdatesReceived.fulfill()
    }

    try await fulfillment(of: [messageUpdatesReceived, chunksReceived])
    #expect(messageUpdateCount == 1)
    #expect(contentUpdateCount == 1)
  }

  @Test("SendOneMessage with text chunks tool use")
  func test_sendOneMessage_withToolCall() async throws {
    let toolCallReceived = expectation(description: "tool Call received")
    let messagesReceived = expectation(description: "All message update received")
    let initialStreamExpectationValidated = expectation(description: "initial stream expectation validated")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      // Wait here to avoid concurrency issues that would make the test flaky.
      try await fulfillment(of: initialStreamExpectationValidated)
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
      sendChunk?("""
        {
          "type": "tool_call",
          "toolName": "read_file",
          "toolUseId": "123",
          "input": {
            "file": "file.txt"
          }
        }
        """.utf8Data)
      return okServerResponse
    }
    let updatingMessage = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestTool<TestToolInput, EmptyObject>(name: "read_file", output: EmptyObject())])
    #expect(updatingMessage.content.count == 0)
    initialStreamExpectationValidated.fulfill()

    var messageUpdateCount = 0
    Task {
      for await message in updatingMessage.updates {
        messageUpdateCount += 1
        if messageUpdateCount == 1 {
          // First update has one piece of text content
          #expect(message.content.count == 1)
          #expect(message.content.first?.asText != nil)
        } else if messageUpdateCount == 2 {
          // Second update has a tool call
          #expect(message.content.count == 2)
          let toolCall = try #require(message.content.last?.asToolUseRequest)
          #expect(toolCall.toolName == "read_file")
          #expect(toolCall.toolUse.toolUseId == "123")
          #expect((toolCall.toolUse.input as? TestToolInput)?.file == "file.txt")
          toolCallReceived.fulfill()
        }
      }
      messagesReceived.fulfill()
    }

    try await fulfillment(of: [toolCallReceived, messagesReceived])
    #expect(messageUpdateCount == 2)
  }

  @Test("SendOneMessage with failed tool use")
  func test_sendOneMessage_withFailedToolCall() async throws {
    let toolCallReceived = expectation(description: "tool Call received")
    let messagesReceived = expectation(description: "All message update received")
    let initialStreamExpectationValidated = expectation(description: "initial stream expectation validated")
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      // Wait here to avoid concurrency issues that would make the test flaky.
      try await fulfillment(of: initialStreamExpectationValidated)
      sendChunk?("""
        {
          "type": "tool_call",
          "toolName": "read_file",
          "toolUseId": "123",
          "input": {
            "badInput": "file.txt"
          }
        }
        """.utf8Data)
      return okServerResponse
    }
    let updatingMessage = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestTool<TestToolInput, EmptyObject>(name: "read_file", output: EmptyObject())])
    #expect(updatingMessage.content.count == 0)
    initialStreamExpectationValidated.fulfill()

    Task {
      for await message in updatingMessage.updates {
        // Second update has a tool call
        #expect(message.content.count == 1)
        let toolCall = try #require(message.content.last?.asToolUseRequest)
        #expect(toolCall.toolName == "read_file")
        #expect(toolCall.toolUse.toolUseId == "123")
        #expect(
          (toolCall.toolUse as? FailedToolUse)?.error
            .localizedDescription ==
            "Could not parse the input for tool read_file: The data couldn’t be read because it is missing.")
        toolCallReceived.fulfill()
      }
      messagesReceived.fulfill()
    }

    try await fulfillment(of: [toolCallReceived, messagesReceived])
  }

  @Test("SendOneMessage fails with CancellationError when cancelled")
  func test_sendOneMessage_isCancelled() async throws {
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
      try await sut.sendOneMessage(
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

  @Test("SendOneMessage stops streaming when cancelled")
  func test_sendOneMessage_stopsStreamingWhenCancelled() async throws {
    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    let requestStarted = expectation(description: "Request started")
    let requestCancelled = expectation(description: "Request cancelled")
    let updateStreamFinished = expectation(description: "Update stream finished")

    server.onPostRequest = { _, _, sendChunk in
      requestStarted.fulfill()

      try await fulfillment(of: requestCancelled)

      // While we expect URLSession to not send and partial response after the request is cancelled,
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
      try await sut.sendOneMessage(
        messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
        tools: [],
        model: .claudeSonnet_4_0,
        context: TestChatContext(projectRoot: URL(filePath: "/path/to/root")),
        handleUpdateStream: { updateStream in
          Task {
            for await _ in updateStream {
              Issue.record("Expected no updates")
            }
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

  @Test("SendOneMessage with streamed tool call receives all input updates")
  func test_sendOneMessage_withStreamedToolCall() async throws {
    let initialStreamExpectationValidated = expectation(description: "initial stream expectation validated")
    let toolCallReceived = expectation(description: "tool Call received")
    let messagesReceived = expectation(description: "All message update received")

    let chunk1Validated = expectation(description: "First chunk validated")
    let chunk2Validated = expectation(description: "Second chunk validated")
    let chunk3Validated = expectation(description: "Third chunk validated")
    let chunk4Validated = expectation(description: "Fourth chunk validated")

    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      // Wait here to avoid concurrency issues that would make the test flaky.
      try await fulfillment(of: initialStreamExpectationValidated)
      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": "{\\"file\\": \\"file.t"
        }
        """.utf8Data)

      try await fulfillment(of: chunk1Validated)
      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": "xt\\""
        }
        """.utf8Data)

      try await fulfillment(of: chunk2Validated)
      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": ", \\"keywords\\":[\\"foo\\", \\"ba"
        }
        """.utf8Data)

      try await fulfillment(of: chunk3Validated)
      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": "r\\"]}"
        }
        """.utf8Data)
      return okServerResponse
    }
    let updatingMessage = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestStreamingTool<TestToolInput, EmptyObject>(name: "TestStreamingTool", output: EmptyObject())])
    #expect(updatingMessage.content.count == 0)
    initialStreamExpectationValidated.fulfill()

    var _toolUse: TestStreamingTool<TestToolInput, EmptyObject>.Use?
    Task {
      for await message in updatingMessage.updates {
        // Second update has a tool call
        #expect(message.content.count == 1)
        let toolUse = try #require(message.content.last?.asToolUseRequest?.toolUse as? TestStreamingTool<
          TestToolInput,
          EmptyObject
        >.Use)
        #expect(toolUse.callingTool.name == "TestStreamingTool")
        #expect(toolUse.toolUseId == "123")
        _toolUse = toolUse
        toolCallReceived.fulfill()
      }
      messagesReceived.fulfill()
    }

    try await fulfillment(of: [toolCallReceived])
    let toolUse = try #require(_toolUse)

    #expect(toolUse.receivedInputs.count == 1)
    #expect(toolUse.receivedInputs.last?.file == "file.t")
    #expect(toolUse.receivedInputs.last?.keywords == nil)
    chunk1Validated.fulfill()

    let counter = Atomic<Int>(1)
    toolUse.onReceiveInput = {
      let i = counter.increment()
      switch i {
      case 2:
        #expect(toolUse.receivedInputs.count == 2)
        #expect(toolUse.receivedInputs.last?.file == "file.txt")
        #expect(toolUse.receivedInputs.last?.keywords == nil)
        chunk2Validated.fulfill()

      case 3:
        #expect(toolUse.receivedInputs.count == 3)
        #expect(toolUse.receivedInputs.last?.file == "file.txt")
        #expect(toolUse.receivedInputs.last?.keywords == ["foo", "ba"])
        chunk3Validated.fulfill()

      case 4:
        #expect(toolUse.receivedInputs.count == 4)
        #expect(toolUse.receivedInputs.last?.file == "file.txt")
        #expect(toolUse.receivedInputs.last?.keywords == ["foo", "bar"])
        #expect(toolUse.hasReceivedAllInput == true)
        chunk4Validated.fulfill()

      default:
        Issue.record("Received unexpected input update #\(i)")
      }
    }

    try await fulfillment(of: [messagesReceived, chunk4Validated])
  }

  @Test("SendOneMessage with streamed tool call works if some updates can't be parsed")
  func test_sendOneMessage_withStreamedToolCall_worksIfSomeUpdateCantBeParsed() async throws {
    let initialStreamExpectationValidated = expectation(description: "initial stream expectation validated")
    let toolCallReceived = expectation(description: "tool Call received")
    let messagesReceived = expectation(description: "All message update received")

    let server = MockServer()
    let sut = DefaultLLMService(server: server)
    server.onPostRequest = { _, _, sendChunk in
      // Wait here to avoid concurrency issues that would make the test flaky.
      try await fulfillment(of: initialStreamExpectationValidated)
      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": "{\\"fil"
        }
        """.utf8Data)

      sendChunk?("""
        {
          "type": "tool_call_delta",
          "toolName": "TestStreamingTool",
          "toolUseId": "123",
          "inputDelta": "e\\": \\"file.txt\\"}"
        }
        """.utf8Data)
      return okServerResponse
    }
    let updatingMessage = try await sut.sendOneMessage(
      messageHistory: [.init(role: .user, content: [.textMessage(.init(text: "hello"))])],
      tools: [TestStreamingTool<TestToolInput, EmptyObject>(name: "TestStreamingTool", output: EmptyObject())])
    #expect(updatingMessage.content.count == 0)
    initialStreamExpectationValidated.fulfill()

    var _toolUse: TestStreamingTool<TestToolInput, EmptyObject>.Use?
    Task {
      for await message in updatingMessage.updates {
        // Second update has a tool call
        #expect(message.content.count == 1)
        let toolUse = try #require(message.content.last?.asToolUseRequest?.toolUse as? TestStreamingTool<
          TestToolInput,
          EmptyObject
        >.Use)
        #expect(toolUse.callingTool.name == "TestStreamingTool")
        #expect(toolUse.toolUseId == "123")
        _toolUse = toolUse
        toolCallReceived.fulfill()
      }
      messagesReceived.fulfill()
    }

    try await fulfillment(of: [toolCallReceived])
    let toolUse = try #require(_toolUse)

    #expect(toolUse.receivedInputs.count == 1)
    #expect(toolUse.receivedInputs.last?.file == "file.txt")
    #expect(toolUse.hasReceivedAllInput == true)

    try await fulfillment(of: [messagesReceived])
  }
}
