// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import ChatFeatureInterface
import Foundation
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockChatHistoryService: ChatHistoryService {

  public init(chatThreads: [ChatThreadModel] = []) {
    self.chatThreads = chatThreads
  }

  public var onSaveChatThread: (@Sendable (ChatThreadModel) async throws -> Void)?

  public var onLoadLastChatThreads: (@Sendable (Int, Int) async throws -> [ChatThreadModelMetadata])?

  public var onLoadChatThread: (@Sendable (UUID) async throws -> ChatThreadModel?)?

  public var onDeleteChatThread: (@Sendable (UUID) async throws -> Void)?

  public func save(chatThread: ChatThreadModel) async throws {
    try await onSaveChatThread?(chatThread)

    if let index = chatThreads.firstIndex(where: { $0.id == chatThread.id }) {
      chatThreads[index] = chatThread
    } else {
      chatThreads.append(chatThread)
    }
  }

  public func loadLastChatThreads(last: Int, offset: Int) async throws -> [ChatThreadModelMetadata] {
    if let customResult = try await onLoadLastChatThreads?(last, offset) {
      return customResult
    }

    let sortedThreads = chatThreads.sorted { $0.createdAt > $1.createdAt }
    let slicedThreads = Array(sortedThreads.dropFirst(offset).prefix(last))

    return slicedThreads.map { thread in
      ChatThreadModelMetadata(
        id: thread.id,
        name: thread.name,
        createdAt: thread.createdAt)
    }
  }

  public func loadChatThread(id: UUID) async throws -> ChatThreadModel? {
    if let customResult = try await onLoadChatThread?(id) {
      return customResult
    }

    return chatThreads.first { $0.id == id }
  }

  public func deleteChatThread(id: UUID) async throws {
    try await onDeleteChatThread?(id)

    chatThreads.removeAll { $0.id == id }
  }

  private var chatThreads: [ChatThreadModel]

}
#endif
