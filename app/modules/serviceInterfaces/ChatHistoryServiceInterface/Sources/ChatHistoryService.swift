// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
import Foundation

// MARK: - ChatHistoryService

public protocol ChatHistoryService: Sendable {
  func loadLastChatThreads(last: Int) async throws -> [ChatThreadModelMetadata]
  func loadChatThread(id: String) async throws -> ChatThreadModel?
  func save(chatThread: ChatThreadModel) async throws
}

// MARK: - ChatThreadModelMetadata

public struct ChatThreadModelMetadata: Sendable {
  public let id: UUID
  public let name: String
  public let createdAt: Date
}
