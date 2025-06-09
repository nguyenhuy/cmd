// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import ConcurrencyFoundation
import Foundation
import FoundationInterfaces
import LLMServiceInterface
import ServerServiceInterface
import Testing
import ToolFoundation
@testable import LLMService

@Suite("RequestStreamingHelper Reasoning Tests")
struct RequestStreamingHelperReasoningTests {

  @Test("Handle reasoning delta creates new reasoning content")
  func testHandleReasoningDeltaCreatesNewContent() async throws {
    let result = MutableCurrentValueStream(AssistantMessage(content: []))
    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    let reasoningDelta = Schema.ReasoningDelta(delta: "Let me think...", idx: 0)
    let chunk = Schema.StreamedResponseChunk.reasoningDelta(reasoningDelta)
    let data = try JSONEncoder().encode(chunk)

    continuation.yield(data)
    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    #expect(finalMessage.content.count == 1)

    guard case .reasoning(let reasoningStream) = finalMessage.content.first else {
      Issue.record("Expected reasoning content")
      return
    }

    let reasoningContent = reasoningStream.value
    #expect(reasoningContent.content == "Let me think...")
    #expect(reasoningContent.deltas == ["Let me think..."])
    #expect(reasoningContent.signature == nil)
  }

  @Test("Handle reasoning delta appends to existing reasoning content")
  func testHandleReasoningDeltaAppendsToExisting() async throws {
    let existingReasoning = ReasoningContentMessage(
      content: "Initial thought",
      deltas: ["Initial thought"])
    let reasoningStream = MutableCurrentValueStream(existingReasoning)
    let result = MutableCurrentValueStream(AssistantMessage(content: [.reasoning(reasoningStream)]))

    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    let reasoningDelta = Schema.ReasoningDelta(delta: " continues...", idx: 0)
    let chunk = Schema.StreamedResponseChunk.reasoningDelta(reasoningDelta)
    let data = try JSONEncoder().encode(chunk)

    continuation.yield(data)
    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    #expect(finalMessage.content.count == 1)

    guard case .reasoning(let updatedReasoningStream) = finalMessage.content.first else {
      Issue.record("Expected reasoning content")
      return
    }

    let reasoningContent = updatedReasoningStream.value
    #expect(reasoningContent.content == "Initial thought continues...")
    #expect(reasoningContent.deltas == ["Initial thought", " continues..."])
    #expect(reasoningContent.signature == nil)
  }

  @Test("Handle reasoning signature sets signature on existing reasoning")
  func testHandleReasoningSignatureOnExisting() async throws {
    let existingReasoning = ReasoningContentMessage(
      content: "Thinking process",
      deltas: ["Thinking process"])
    let reasoningStream = MutableCurrentValueStream(existingReasoning)
    let result = MutableCurrentValueStream(AssistantMessage(content: [.reasoning(reasoningStream)]))

    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    let reasoningSignature = Schema.ReasoningSignature(signature: "signature123", idx: 0)
    let chunk = Schema.StreamedResponseChunk.reasoningSignature(reasoningSignature)
    let data = try JSONEncoder().encode(chunk)

    continuation.yield(data)
    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    guard case .reasoning(let updatedReasoningStream) = finalMessage.content.first else {
      Issue.record("Expected reasoning content")
      return
    }

    let reasoningContent = updatedReasoningStream.value
    #expect(reasoningContent.content == "Thinking process")
    #expect(reasoningContent.deltas == ["Thinking process"])
    #expect(reasoningContent.signature == "signature123")
  }

  @Test("Handle reasoning signature creates new reasoning content when none exists")
  func testHandleReasoningSignatureCreatesNew() async throws {
    let result = MutableCurrentValueStream(AssistantMessage(content: []))
    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    let reasoningSignature = Schema.ReasoningSignature(signature: "signature456", idx: 0)
    let chunk = Schema.StreamedResponseChunk.reasoningSignature(reasoningSignature)
    let data = try JSONEncoder().encode(chunk)

    continuation.yield(data)
    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    #expect(finalMessage.content.count == 1)

    guard case .reasoning(let reasoningStream) = finalMessage.content.first else {
      Issue.record("Expected reasoning content")
      return
    }

    let reasoningContent = reasoningStream.value
    #expect(reasoningContent.content == "")
    #expect(reasoningContent.deltas == [])
    #expect(reasoningContent.signature == "signature456")
  }

  @Test("Reasoning content ends when text content starts")
  func testReasoningContentEndsWhenTextStarts() async throws {
    let existingReasoning = ReasoningContentMessage(
      content: "Initial reasoning",
      deltas: ["Initial reasoning"])
    let reasoningStream = MutableCurrentValueStream(existingReasoning)
    let result = MutableCurrentValueStream(AssistantMessage(content: [.reasoning(reasoningStream)]))

    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    // First send reasoning delta
    let reasoningDelta = Schema.ReasoningDelta(delta: " more reasoning", idx: 0)
    let reasoningChunk = Schema.StreamedResponseChunk.reasoningDelta(reasoningDelta)
    let reasoningData = try JSONEncoder().encode(reasoningChunk)

    // Then send text delta
    let textDelta = Schema.TextDelta(text: "Now for the response", idx: 1)
    let textChunk = Schema.StreamedResponseChunk.textDelta(textDelta)
    let textData = try JSONEncoder().encode(textChunk)

    continuation.yield(reasoningData)
    continuation.yield(textData)
    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    #expect(finalMessage.content.count == 2)

    // Check reasoning content was finished and has expected content
    guard case .reasoning(let reasoningStream) = finalMessage.content[0] else {
      Issue.record("Expected reasoning content first")
      return
    }

    let reasoningContent = reasoningStream.value
    #expect(reasoningContent.content == "Initial reasoning more reasoning")
    #expect(reasoningContent.deltas == ["Initial reasoning", " more reasoning"])

    // Check text content was created
    guard case .text(let textStream) = finalMessage.content[1] else {
      Issue.record("Expected text content second")
      return
    }

    let textContent = textStream.value
    #expect(textContent.content == "Now for the response")
    #expect(textContent.deltas == ["Now for the response"])
  }

  @Test("Multiple reasoning deltas are processed correctly")
  func testMultipleReasoningDeltas() async throws {
    let result = MutableCurrentValueStream(AssistantMessage(content: []))
    let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

    let helper = RequestStreamingHelper(
      stream: stream,
      result: result,
      tools: [],
      context: TestChatContext(projectRoot: URL(filePath: "/test")),
      isTaskCancelled: { false },
      repeatDebugHelper: RepeatDebugHelper(userDefaults: MockUserDefaults()))

    let deltas = [
      Schema.ReasoningDelta(delta: "First thought", idx: 0),
      Schema.ReasoningDelta(delta: " then second", idx: 1),
      Schema.ReasoningDelta(delta: " and third", idx: 2),
    ]

    for delta in deltas {
      let chunk = Schema.StreamedResponseChunk.reasoningDelta(delta)
      let data = try JSONEncoder().encode(chunk)
      continuation.yield(data)
    }

    continuation.finish()

    try await helper.processStream()

    let finalMessage = result.value
    #expect(finalMessage.content.count == 1)

    guard case .reasoning(let reasoningStream) = finalMessage.content.first else {
      Issue.record("Expected reasoning content")
      return
    }

    let reasoningContent = reasoningStream.value
    #expect(reasoningContent.content == "First thought then second and third")
    #expect(reasoningContent.deltas == ["First thought", " then second", " and third"])
  }
}
