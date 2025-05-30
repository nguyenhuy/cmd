// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFoundation
import ConcurrencyFoundation
import Foundation
import LLMFoundation
import ServerServiceInterface
import ToolFoundation

public typealias UpdateStream = CurrentValueStream<[CurrentValueStream<AssistantMessage>]>

// MARK: - ChatContext

public protocol ChatContext: Sendable {
  /// The path to the project that is being worked on.
  var project: URL? { get }
  /// The root of the project that is being worked on.
  /// For a Swift package this is the same as the project. For an xcodeproj this is the containing directory.
  var projectRoot: URL? { get }

  /// When a tool that is not read-only runs, this function will be called before.
  var prepareForWriteToolUse: @Sendable () async -> Void { get }
  /// Which chat mode applies to the current context.
  var chatMode: ChatMode { get }
}

// MARK: - LLMService

public protocol LLMService: Sendable {
  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any Tool],
    model: LLMModel,
    context: ChatContext,
    handleUpdateStream: (UpdateStream) -> Void)
    async throws -> [AssistantMessage]
}

#if DEBUG
// TODO: Remove this once tests have been migrated to use the new API.
extension LLMService {
  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any Tool],
    model: LLMModel,
    context: ChatContext,
    handleUpdateStream: (UpdateStream) -> Void)
    async throws -> [AssistantMessage]
  {
    try await sendMessage(
      messageHistory: messageHistory,
      tools: tools,
      model: model,
      context: context,
      handleUpdateStream: handleUpdateStream)
  }
}
#endif
