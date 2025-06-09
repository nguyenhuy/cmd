// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Foundation
import LLMFoundation
import ServerServiceInterface
import ThreadSafe
import ToolFoundation

#if DEBUG
@ThreadSafe
public final class MockLLMService: LLMService {

  public init() { }

  public var projectRoot = URL(filePath: "/")

  public var onSendMessage: (@Sendable (
    [Schema.Message],
    [any Tool],
    LLMModel,
    ChatContext,
    (UpdateStream) -> Void)
    -> [AssistantMessage])?

  public var onIsWithinRoot: @Sendable (URL) -> Bool = { _ in true }

  public var onResolve: @Sendable (String) -> URL = { URL(fileURLWithPath: $0) }

  public func resolve(path: String) -> URL {
    onResolve(path)
  }

  public func isWithinRoot(path: URL) -> Bool {
    onIsWithinRoot(path)
  }

  // MARK: - LLMService

  public func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any Tool],
    model: LLMModel,
    context: any ChatContext,
    handleUpdateStream: (UpdateStream) -> Void)
    async throws -> [AssistantMessage]
  {
    if let onSendMessage {
      return onSendMessage(messageHistory, tools, model, context, handleUpdateStream)
    }

    // Default implementation returning empty array if no handler is set
    return []
  }

}
#endif
