// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatHistoryServiceInterface

// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatHistoryServiceInterface
import DependencyFoundation
import Foundation
import FoundationInterfaces
import GRDB
import LLMServiceInterface
import LoggingServiceInterface

let logger = defaultLogger.subLogger(subsystem: "chatHistoryService")

// MARK: - DefaultChatHistoryService

final class DefaultChatHistoryService: ChatHistoryService, @unchecked Sendable {
  init(createDBConnection: () -> DatabaseQueue) {
    dbQueue = createDBConnection()
  }

  func setup() async throws {
    try await dbQueue.write { db in
      try self.createTables(db)
    }
    logger.log("Database tables created successfully")
  }

  // MARK: - Chat Tab Operations

  func saveChatTab(_ tab: ChatTabModel) async throws {
    try await dbQueue.write { db in
      try tab.save(db)
    }
  }

  func loadChatTabs() async throws -> [ChatTabModel] {
    try await dbQueue.read { db in
      try ChatTabModel.order(Column("updatedAt").desc).fetchAll(db)
    }
  }

  func deleteChatTab(id: String) async throws {
    _ = try await dbQueue.write { db in
      try ChatTabModel.deleteOne(db, id: id)
    }
  }

  // MARK: - Chat Message Operations

  func saveChatMessage(_ message: ChatMessageModel) async throws {
    try await dbQueue.write { db in
      try message.save(db)
    }
  }

  func loadChatMessages(for chatTabId: String) async throws -> [ChatMessageModel] {
    try await dbQueue.read { db in
      try ChatMessageModel
        .filter(Column("chatTabId") == chatTabId)
        .order(Column("createdAt").asc)
        .fetchAll(db)
    }
  }

  // MARK: - Chat Message Content Operations

  func saveChatMessageContent(_ content: ChatMessageContentModel) async throws {
    try await dbQueue.write { db in
      try content.save(db)
    }
  }

  func updateChatMessageContent(_ content: ChatMessageContentModel) async throws {
    let updatedContent = ChatMessageContentModel(
      id: content.id,
      chatMessageId: content.chatMessageId,
      type: content.type,
      text: content.text,
      projectRoot: content.projectRoot,
      isStreaming: content.isStreaming,
      signature: content.signature,
      reasoningDuration: content.reasoningDuration,
      toolName: content.toolName,
      toolInput: content.toolInput,
      toolResult: content.toolResult)
    try await dbQueue.write { db in
      try updatedContent.update(db)
    }
  }

  func loadChatMessageContents(for messageId: String) async throws -> [ChatMessageContentModel] {
    try await dbQueue.read { db in
      try ChatMessageContentModel
        .filter(Column("chatMessageId") == messageId)
        .order(Column("createdAt").asc)
        .fetchAll(db)
    }
  }

  // MARK: - Attachment Operations

  func saveAttachment(_ attachment: AttachmentModel) async throws {
    try await dbQueue.write { db in
      try attachment.save(db)
    }
  }

  func loadAttachments(for contentId: String) async throws -> [AttachmentModel] {
    try await dbQueue.read { db in
      try AttachmentModel
        .filter(Column("chatMessageContentId") == contentId)
        .order(Column("createdAt").asc)
        .fetchAll(db)
    }
  }

  // MARK: - Chat Event Operations

  func saveChatEvent(_ event: ChatEventModel) async throws {
    try await dbQueue.write { db in
      try event.save(db)
    }
  }

  func loadChatEvents(for chatTabId: String) async throws -> [ChatEventModel] {
    try await dbQueue.read { db in
      try ChatEventModel
        .filter(Column("chatTabId") == chatTabId)
        .order(Column("orderIndex").asc)
        .fetchAll(db)
    }
  }

  // MARK: - Atomic Operations

  func saveChatTabAtomic(
    tab: ChatTabModel,
    newMessages: [ChatMessageModel],
    messageContents: [ChatMessageContentModel],
    attachments: [AttachmentModel],
    newEvents: [ChatEventModel])
    async throws
  {
    try await dbQueue.write { db in
      // Save or update the tab
      try tab.save(db)

      // Save new messages
      for message in newMessages {
        try message.save(db)
      }

      // Save new message contents
      for content in messageContents {
        try content.save(db)
      }

      // Save new attachments
      for attachment in attachments {
        try attachment.save(db)
      }

      // Save new events
      for event in newEvents {
        try event.save(db)
      }
    }

    logger
      .log(
        "Atomically saved chat tab: \(tab.name) with \(newMessages.count) new messages, \(messageContents.count) contents, \(attachments.count) attachments, \(newEvents.count) events")
  }

  private let dbQueue: DatabaseQueue

  private func createTables(_ db: Database) throws {
    // Create chat_tabs table
    try db.create(table: ChatTabModel.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("name", .text).notNull()
      t.column("createdAt", .datetime).notNull()
      t.column("updatedAt", .datetime).notNull()
      t.column("projectPath", .text)
      t.column("projectRootPath", .text)
    }

    // Create chat_messages table
    try db.create(table: ChatMessageModel.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatTabId", .text).notNull().references("chat_tabs", onDelete: .cascade)
      t.column("role", .text).notNull()
      t.column("createdAt", .datetime).notNull()
      t.column("updatedAt", .datetime).notNull()
    }

    // Create chat_message_contents table
    try db.create(table: ChatMessageContentModel.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatMessageId", .text).notNull().references("chat_messages", onDelete: .cascade)
      t.column("type", .text).notNull()
      t.column("text", .text)
      t.column("projectRoot", .text)
      t.column("isStreaming", .boolean).notNull().defaults(to: false)
      t.column("signature", .text)
      t.column("reasoningDuration", .double)
      t.column("toolName", .text)
      t.column("toolInput", .text)
      t.column("toolResult", .text)
      t.column("createdAt", .datetime).notNull()
      t.column("updatedAt", .datetime).notNull()
    }

    // Create attachments table
    try db.create(table: AttachmentModel.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatMessageContentId", .text).notNull().references("chat_message_contents", onDelete: .cascade)
      t.column("type", .text).notNull()
      t.column("filePath", .text)
      t.column("fileContent", .text)
      t.column("startLine", .integer)
      t.column("endLine", .integer)
      t.column("imageData", .blob)
      t.column("createdAt", .datetime).notNull()
    }

    // Create chat_events table
    try db.create(table: ChatEventModel.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatTabId", .text).notNull().references("chat_tabs", onDelete: .cascade)
      t.column("type", .text).notNull()
      t.column("chatMessageContentId", .text).references("chat_message_contents", onDelete: .cascade)
      t.column("checkpointId", .text)
      t.column("role", .text)
      t.column("failureReason", .text)
      t.column("createdAt", .datetime).notNull()
      t.column("orderIndex", .integer).notNull()
    }

    // Create indexes for better performance
    try db.create(
      index: "idx_chat_messages_tab_id",
      on: ChatMessageModel.databaseTableName,
      columns: ["chatTabId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_message_contents_message_id",
      on: ChatMessageContentModel.databaseTableName,
      columns: ["chatMessageId"],
      ifNotExists: true)
    try db.create(
      index: "idx_attachments_content_id",
      on: AttachmentModel.databaseTableName,
      columns: ["chatMessageContentId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_events_tab_id",
      on: ChatEventModel.databaseTableName,
      columns: ["chatTabId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_events_order",
      on: ChatEventModel.databaseTableName,
      columns: ["chatTabId", "orderIndex"],
      ifNotExists: true)
  }

}

// MARK: - ChatTabModel + FetchableRecord, PersistableRecord

extension ChatTabModel: FetchableRecord, PersistableRecord {
  public static let databaseTableName = "chat_tabs"
}

// MARK: - ChatMessageModel + FetchableRecord, PersistableRecord

extension ChatMessageModel: FetchableRecord, PersistableRecord {
  public static let databaseTableName = "chat_messages"
}

// MARK: - ChatMessageContentModel + FetchableRecord, PersistableRecord

extension ChatMessageContentModel: FetchableRecord, PersistableRecord {
  public static let databaseTableName = "chat_message_contents"
}

// MARK: - AttachmentModel + FetchableRecord, PersistableRecord

extension AttachmentModel: FetchableRecord, PersistableRecord {
  public static let databaseTableName = "attachments"
}

// MARK: - ChatEventModel + FetchableRecord, PersistableRecord

extension ChatEventModel: FetchableRecord, PersistableRecord {
  public static let databaseTableName = "chat_events"
}

extension BaseProviding where Self: FileManagerProviding {
  public var chatHistoryService: ChatHistoryService {
    shared {
      DefaultChatHistoryService {
        do {
          // Create database directory if it doesn't exist
          let documentsURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
          guard let documentsURL = documentsURLs.first else {
            throw NSError(
              domain: "ChatDatabaseService",
              code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Could not find documents directory"])
          }
          let chatDataURL = documentsURL.appendingPathComponent("ChatData")

          if !fileManager.fileExists(atPath: chatDataURL.path) {
            try fileManager.createDirectory(at: chatDataURL, withIntermediateDirectories: true, attributes: nil)
          }

          let dbURL = chatDataURL.appendingPathComponent("chat.sqlite")
          let connection = try DatabaseQueue(path: dbURL.path)
          logger.log("Database initialized at: \(dbURL.path)")
          return connection
        } catch {
          logger.error("Failed to create database connection", error)
          return try! DatabaseQueue()
        }
      }
    }
  }
}
