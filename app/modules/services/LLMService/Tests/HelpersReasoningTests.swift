// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import LLMServiceInterface
import ServerServiceInterface
import Testing
@testable import LLMService

@Suite("Helpers Reasoning Tests")
struct HelpersReasoningTests {

  @Test("AssistantMessageContent asReasoning returns reasoning stream when content is reasoning")
  func testAsReasoningReturnsReasoningStream() {
    let reasoningMessage = ReasoningContentMessage(
      content: "Thinking about this problem...",
      deltas: ["Thinking", " about", " this", " problem..."],
      signature: "sig123")
    let reasoningStream = MutableCurrentValueStream(reasoningMessage)
    let content = AssistantMessageContent.reasoning(reasoningStream)

    let result = content.asReasoning
    #expect(result != nil)
    #expect(result?.value.content == "Thinking about this problem...")
    #expect(result?.value.signature == "sig123")
  }

  @Test("AssistantMessageContent asReasoning returns nil when content is text")
  func testAsReasoningReturnsNilForTextContent() {
    let textMessage = TextContentMessage(content: "Hello world", deltas: ["Hello", " world"])
    let textStream = MutableCurrentValueStream(textMessage)
    let content = AssistantMessageContent.text(textStream)

    let result = content.asReasoning
    #expect(result == nil)
  }
}
