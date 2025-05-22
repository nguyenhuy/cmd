// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import Foundation
@preconcurrency import SwiftOpenAI
import ThreadSafe

#if DEBUG
/// This debugging helper allows to repeat the last saved interaction with an LLM.
/// Toggle Repeat last chat session in the settings to enable/disable this feature.
///
/// This can be helpful when iterating on an issue to avoid waiting on the LLM and dealing with not receiving the same responses.
///
/// Not the best code, but it does the job. DEBUG only.
@ThreadSafe
final class RepeatDebugHelper: Sendable {
  init() {
    isRepeating = storage.bool(forKey: "llmService.isRepeating")
    startSession()
  }

  let storage = UserDefaults.standard
  let isRepeating: Bool

  var streams: [Stream] = []
  var streamStartedAt: Date?

  func startSession() {
    if !isRepeating { return }
    guard
      let streamsData = storage.data(forKey: "llmService.savedStreams"),
      let streams = try? JSONDecoder().decode([Stream].self, from: streamsData)
    else { return }
    self.streams = streams
  }

  func receive(chunk: ChatCompletionChunkObject) {
    if isRepeating { return }
    let streams = safelyMutate { state in
      if let streamStartedAt = state.streamStartedAt, var stream = state.streams.last {
        stream.chunks.append(.init(chunk: chunk, receivedAfter: Date().timeIntervalSince(streamStartedAt)))
        state.streams[state.streams.count - 1] = stream
      } else {
        state.streamStartedAt = Date()
        state.streams.append(Stream(chunks: [.init(chunk: chunk, receivedAfter: 0)]))
      }
      return state.streams
    }
    storage.set(try? JSONEncoder().encode(streams), forKey: "llmService.savedStreams")
  }

  func streamCompleted() {
    if isRepeating { return }
    safelyMutate { state in
      state.streamStartedAt = nil
    }
  }

  func repeatStream() throws -> AsyncThrowingStream<ChatCompletionChunkObject, any Error>? {
    guard isRepeating else { return nil }
    let stream: Stream? = safelyMutate { state in
      if state.streams.isEmpty {
        return nil
      }
      return state.streams.removeFirst()
    }
    guard let stream else {
      throw AppError("no more saved stream to repeat")
    }
    return AsyncThrowingStream { continuation in
      Task {
        for chunk in stream.chunks {
          continuation.yield(chunk.chunk)
        }
        continuation.finish()
      }
    }
  }

}

struct Stream: Codable {
  var chunks: [Chunk]

  struct Chunk: Codable {
    var chunk: ChatCompletionChunkObject
    var receivedAfter: TimeInterval
  }
}

extension ChatCompletionChunkObject: @retroactive Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encodeIfPresent(choices, forKey: .choices)
    try container.encodeIfPresent(created, forKey: .created)
    try container.encodeIfPresent(model, forKey: .model)
    try container.encodeIfPresent(serviceTier, forKey: .serviceTier)
    try container.encodeIfPresent(systemFingerprint, forKey: .systemFingerprint)
    try container.encodeIfPresent(object, forKey: .object)
  }

  enum CodingKeys: String, CodingKey {
    case id, choices, created, model, object, usage
    case serviceTier = "service_tier"
    case systemFingerprint = "system_fingerprint"
  }
}

extension ChatCompletionChunkObject.ChatChoice: @retroactive Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(delta, forKey: .delta)
    try container.encodeIfPresent(finishReason, forKey: .finishReason)
    try container.encodeIfPresent(index, forKey: .index)
  }

  enum CodingKeys: String, CodingKey {
    case delta, index, logprobs
    case finishReason = "finish_reason"
    case finishDetails = "finish_details"
  }
}

extension ChatCompletionChunkObject.ChatChoice.Delta: @retroactive Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encodeIfPresent(reasoningContent, forKey: .reasoningContent)
    try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
    try container.encodeIfPresent(role, forKey: .role)
    try container.encodeIfPresent(refusal, forKey: .refusal)
  }

  enum CodingKeys: String, CodingKey {
    case content, role, refusal
    case reasoningContent = "reasoning_content"
    case toolCalls = "tool_calls"
    case functionCall = "function_call"
  }
}

extension IntOrStringValue: @retroactive Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .int(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    }
  }
}
#endif
