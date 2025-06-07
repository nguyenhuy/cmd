// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - ChatHistoryServiceInterface

public protocol ChatHistoryService: Sendable {
  func setup() async throws

  // Chat Tab Operations
  func saveChatTab(_ tab: ChatTabModel) async throws
  func loadChatTabs() async throws -> [ChatTabModel]
//  func deleteChatTab(id: String) async throws

  /// Chat Message Operations
  ///  func saveChatMessage(_ message: ChatMessageModel) async throws
  func loadChatMessages(for chatTabId: String) async throws -> [ChatMessageModel]

  /// Chat Message Content Operations
  ///  func saveChatMessageContent(_ content: ChatMessageContentModel) async throws
  ///  func updateChatMessageContent(_ content: ChatMessageContentModel) async throws
  func loadChatMessageContents(for messageId: String) async throws -> [ChatMessageContentModel]

  /// Attachment Operations
  ///  func saveAttachment(_ attachment: AttachmentModel) async throws
  func loadAttachments(for contentId: String) async throws -> [AttachmentModel]

  /// Chat Event Operations
  ///  func saveChatEvent(_ event: ChatEventModel) async throws
  func loadChatEvents(for chatTabId: String) async throws -> [ChatEventModel]

  /// Atomic Operations
  func saveChatTabAtomic(
    tab: ChatTabModel,
    newMessages: [ChatMessageModel],
    messageContents: [ChatMessageContentModel],
    attachments: [AttachmentModel],
    newEvents: [ChatEventModel])
    async throws
}
