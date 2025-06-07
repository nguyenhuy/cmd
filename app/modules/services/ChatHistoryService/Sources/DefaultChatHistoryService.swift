// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
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
  init(
    createDBConnection: () -> DatabaseQueue,
    fileManager: FileManagerI)
  {
    self.fileManager = fileManager
    dbQueue = createDBConnection()

    Task {
      do {
        try await dbQueue.write { db in
          try self.createTables(db)
        }
        logger.log("Database tables created successfully")
      } catch {
        logger.error("Database tables could not be created. Chat history will not work", error)
      }
    }
  }

  // MARK: - Chat Thread Operations

  func save(chatThread thread: ChatThreadModel) async throws {
    let home = fileManager.homeDirectoryForCurrentUser
    let rawContentPath = home
      .appending(path: ".cmd/chat-history/\(thread.projectInfo?.dirPath.hashValue ?? 0)/\(thread.id.uuidString).json")

    let threadRecord = ChatThreadRecord(
      id: thread.id.uuidString,
      name: thread.name,
      createdAt: thread.createdAt,
      rawContentLocation: rawContentPath.path)

    try await dbQueue.write { db in
      // Save or update the thread
      try threadRecord.save(db)
    }
  }

  func loadLastChatThreads(last _: Int) async throws -> [ChatThreadModelMetadata] {
    []
  }

  func loadChatThread(id: String) async throws -> ChatThreadModel? {
    try await dbQueue.read { db in
      guard let threadRecord = try ChatThreadRecord.fetchOne(db, id: id) else {
        throw NSError(
          domain: "ChatHistoryService",
          code: 404,
          userInfo: [NSLocalizedDescriptionKey: "Chat thread with ID \(id) not found"])
      }

      // Load messages for this thread
      let messageRecords = try ChatMessageRecord
        .filter(Column("chatThreadId") == threadRecord.id)
        .order(Column("createdAt").asc)
        .fetchAll(db)

      var messages: [ChatMessageModel] = []
      for messageRecord in messageRecords {
        // Load contents for this message
        let contentRecords = try ChatMessageContentRecord
          .filter(Column("chatMessageId") == messageRecord.id)
          .order(Column("createdAt").asc)
          .fetchAll(db)

        var contents: [ChatMessageContentModel] = []
        for contentRecord in contentRecords {
          // Load attachments for this content
          let attachmentRecords = try AttachmentRecord
            .filter(Column("chatMessageContentId") == contentRecord.id)
            .order(Column("createdAt").asc)
            .fetchAll(db)

          let attachments = attachmentRecords.compactMap { try? AttachmentModel(from: $0, db: db) }
          let content = ChatMessageContentModel(from: contentRecord, attachments: attachments)
          contents.append(content)
        }

        let message = ChatMessageModel(from: messageRecord, contents: contents)
        messages.append(message)
      }

      // Load events for this thread
      let eventRecords = try ChatEventRecord
        .filter(Column("chatThreadId") == threadRecord.id)
        .order(Column("orderIndex").asc)
        .fetchAll(db)

      var events: [ChatEventModel] = []
      for eventRecord in eventRecords {
        var messageContent: ChatMessageContentModel?

        // If this event references a message content, find it
        if let contentId = eventRecord.chatMessageContentId {
          // Find the content in the already loaded messages
          for message in messages {
            for content in message.content {
              if content.id.uuidString == contentId {
                messageContent = content
                break
              }
            }
            if messageContent != nil { break }
          }
        }

        let event = ChatEventModel(from: eventRecord, messageContent: messageContent)
        events.append(event)
      }

      return ChatThreadModel(from: threadRecord, messages: messages, events: events)
    }
  }

  private let fileManager: FileManagerI

  // MARK: - Atomic Operations

  private let dbQueue: DatabaseQueue

  private func createTables(_ db: Database) throws {
    // Create chat_threads table
    try db.create(table: ChatThreadRecord.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("name", .text).notNull()
      t.column("createdAt", .datetime).notNull()
      t.column("updatedAt", .datetime).notNull()
      t.column("projectPath", .text)
      t.column("projectRootPath", .text)
    }

    // Create chat_messages table
    try db.create(table: ChatMessageRecord.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatThreadId", .text).notNull().references("chat_threads", onDelete: .cascade)
      t.column("role", .text).notNull()
      t.column("createdAt", .datetime).notNull()
      t.column("updatedAt", .datetime).notNull()
    }

    // Create chat_message_contents table
    try db.create(table: ChatMessageContentRecord.databaseTableName, ifNotExists: true) { t in
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
    try db.create(table: AttachmentRecord.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatMessageContentId", .text).notNull().references("chat_message_contents", onDelete: .cascade)
      t.column("type", .text).notNull()
      t.column("filePath", .text)
      t.column("fileContent", .text)
      t.column("startLine", .integer)
      t.column("endLine", .integer)
      t.column("imageData", .blob) // TODO: Handle image data properly
      t.column("createdAt", .datetime).notNull()
    }

    // Create chat_events table
    try db.create(table: ChatEventRecord.databaseTableName, ifNotExists: true) { t in
      t.primaryKey("id", .text)
      t.column("chatThreadId", .text).notNull().references("chat_threads", onDelete: .cascade)
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
      index: "idx_chat_messages_thread_id",
      on: ChatMessageRecord.databaseTableName,
      columns: ["chatThreadId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_message_contents_message_id",
      on: ChatMessageContentRecord.databaseTableName,
      columns: ["chatMessageId"],
      ifNotExists: true)
    try db.create(
      index: "idx_attachments_content_id",
      on: AttachmentRecord.databaseTableName,
      columns: ["chatMessageContentId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_events_thread_id",
      on: ChatEventRecord.databaseTableName,
      columns: ["chatThreadId"],
      ifNotExists: true)
    try db.create(
      index: "idx_chat_events_order",
      on: ChatEventRecord.databaseTableName,
      columns: ["chatThreadId", "orderIndex"],
      ifNotExists: true)
  }

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

extension ChatMessageContentModel {
  var asText: ChatMessageTextContentModel? {
    guard case .text(let textContent) = self else { return nil }
    return textContent
  }

  var id: UUID {
    switch self {
    case .text(let content):
      content.id
    case .reasoning(let content):
      content.id
    case .nonUserFacingText(let content):
      content.id
    case .toolUse(let content):
      content.id
    }
  }
}
