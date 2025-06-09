// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import ChatFeatureInterface
import Foundation

// MARK: - ChatHistoryService

public protocol ChatHistoryService: Sendable {
  func loadLastChatThreads(last: Int, offset: Int) async throws -> [ChatThreadModelMetadata]
  func loadChatThread(id: UUID) async throws -> ChatThreadModel?
  func save(chatThread: ChatThreadModel) async throws
  func deleteChatThread(id: UUID) async throws
}

// MARK: - ChatThreadModelMetadata

public struct ChatThreadModelMetadata: Sendable {
  public let id: UUID
  public let name: String
  public let createdAt: Date

  public init(id: UUID, name: String, createdAt: Date) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
  }
}
