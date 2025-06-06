// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import Testing

@testable import Chat

// MARK: - ChatMessageReasoningContentTests

@MainActor
struct ChatMessageReasoningContentTests {

  @Test("initialization with single delta creates content")
  func test_initialization_withSingleDelta() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Initial reasoning text"],
      signature: "test-signature",
      isStreaming: true)

    #expect(reasoning.text == "Initial reasoning text")
    #expect(reasoning.signature == "test-signature")
    #expect(reasoning.isStreaming == true)
    #expect(reasoning.reasoningDuration == nil)
  }

  @Test("initialization with multiple deltas concatenates text")
  func test_initialization_withMultipleDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["First part ", "second part ", "third part"],
      signature: nil,
      isStreaming: false)

    #expect(reasoning.text == "First part second part third part")
    #expect(reasoning.signature == nil)
    #expect(reasoning.isStreaming == false)
  }

  @Test("initialization with empty deltas creates empty content")
  func test_initialization_withEmptyDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: [],
      signature: nil)

    #expect(reasoning.text == "")
    #expect(reasoning.isStreaming == true)
    #expect(reasoning.reasoningDuration == nil)
  }

  @Test("catchUp with new deltas appends text")
  func test_catchUp_withNewDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Initial text"],
      signature: nil)

    #expect(reasoning.text == "Initial text")

    reasoning.catchUp(deltas: ["Initial text", " additional", " content"])

    #expect(reasoning.text == "Initial text additional content")
  }

  @Test("catchUp with same deltas does not change text")
  func test_catchUp_withSameDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Initial text", " more text"],
      signature: nil)

    let originalText = reasoning.text
    reasoning.catchUp(deltas: ["Initial text", " more text"])

    #expect(reasoning.text == originalText)
  }

  @Test("catchUp with fewer deltas does not change text")
  func test_catchUp_withFewerDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Initial text", " more text"],
      signature: nil)

    let originalText = reasoning.text
    reasoning.catchUp(deltas: ["Initial text"])

    #expect(reasoning.text == originalText)
  }

  @Test("finishStreaming sets isStreaming to false and calculates duration")
  func test_finishStreaming() async {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Test content"],
      signature: nil,
      isStreaming: true)

    #expect(reasoning.isStreaming == true)
    #expect(reasoning.reasoningDuration == nil)

    reasoning.finishStreaming()

    #expect(reasoning.isStreaming == false)
    #expect(reasoning.reasoningDuration != nil)
    #expect(reasoning.reasoningDuration! > 0)
  }

  @Test("finishStreaming when already finished doesn't recalculates duration")
  func test_finishStreaming_whenAlreadyFinished() async {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Test content"],
      signature: nil,
      isStreaming: true)
    reasoning.finishStreaming()

    let firstDuration = reasoning.reasoningDuration
    #expect(firstDuration != nil)

    reasoning.finishStreaming()

    // Duration gets recalculated on each call
    #expect(reasoning.reasoningDuration! == firstDuration!)
    #expect(reasoning.isStreaming == false)
  }

  @Test("equatable by identifier works correctly")
  func test_equatableByIdentifier() {
    let reasoning1 = ChatMessageReasoningContent(
      deltas: ["Content 1"],
      signature: nil)

    let reasoning2 = ChatMessageReasoningContent(
      deltas: ["Content 2"],
      signature: nil)

    // Same instance should be equal to itself
    #expect(reasoning1 == reasoning1)

    // Different instances should not be equal
    #expect(reasoning1 != reasoning2)

    // IDs should be different
    #expect(reasoning1.id != reasoning2.id)
  }

  @Test("debug convenience initializer with text")
  func test_debugInitializer_withText() {
    let reasoning = ChatMessageReasoningContent(
      text: "Debug text content",
      signature: "debug-sig",
      isStreaming: false)

    #expect(reasoning.text == "Debug text content")
    #expect(reasoning.signature == "debug-sig")
    #expect(reasoning.isStreaming == false)
  }

  @Test("debug convenience initializer with deltas")
  func test_debugInitializer_withDeltas() {
    let reasoning = ChatMessageReasoningContent(
      deltas: ["Debug ", "delta ", "content"],
      isStreaming: true)

    #expect(reasoning.text == "Debug delta content")
    #expect(reasoning.signature == nil)
    #expect(reasoning.isStreaming == true)
  }

  @Test("streaming behavior with progressive content building")
  func test_streamingBehavior() async {
    let reasoning = ChatMessageReasoningContent(
      deltas: [],
      signature: nil,
      isStreaming: true)

    #expect(reasoning.text == "")
    #expect(reasoning.isStreaming == true)

    // Simulate streaming deltas
    reasoning.catchUp(deltas: ["Thinking about "])
    #expect(reasoning.text == "Thinking about ")
    #expect(reasoning.isStreaming == true)

    reasoning.catchUp(deltas: ["Thinking about ", "the problem "])
    #expect(reasoning.text == "Thinking about the problem ")
    #expect(reasoning.isStreaming == true)

    reasoning.catchUp(deltas: ["Thinking about ", "the problem ", "and considering solutions..."])
    #expect(reasoning.text == "Thinking about the problem and considering solutions...")
    #expect(reasoning.isStreaming == true)

    reasoning.finishStreaming()
    #expect(reasoning.isStreaming == false)
    #expect(reasoning.reasoningDuration != nil)
  }

  @Test("signature can be nil or present")
  func test_signature_variations() {
    let reasoningWithSignature = ChatMessageReasoningContent(
      deltas: ["Content"],
      signature: "model-signature-123")

    let reasoningWithoutSignature = ChatMessageReasoningContent(
      deltas: ["Content"],
      signature: nil)

    #expect(reasoningWithSignature.signature == "model-signature-123")
    #expect(reasoningWithoutSignature.signature == nil)
  }
}
