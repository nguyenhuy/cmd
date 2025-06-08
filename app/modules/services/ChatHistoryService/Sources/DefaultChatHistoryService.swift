// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
import ChatHistoryServiceInterface
import CryptoKit
import DependencyFoundation
import Foundation
import FoundationInterfaces
import GRDB
import LLMServiceInterface
import LoggingServiceInterface
import ToolFoundation

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
      .appending(
        path: ".cmd/chat-history/project-\(thread.projectInfo?.dirPath.path.sha256 ?? "sha256")-\(thread.projectInfo?.dirPath.lastPathComponent ?? "")/\(thread.createdAt.ISO8601Format())-\(thread.id.uuidString)/content.json")

    let threadRecord = ChatThreadRecord(
      id: thread.id.uuidString,
      name: thread.name,
      createdAt: thread.createdAt,
      rawContentPath: rawContentPath.path)

    try await dbQueue.write { db in
      // Save or update the thread
      try threadRecord.save(db)
    }
    try fileManager.createDirectory(
      at: rawContentPath.deletingLastPathComponent(),
      withIntermediateDirectories: true,
      attributes: nil)
    let encoder = JSONEncoder()

    let objectsDir = rawContentPath.deletingLastPathComponent().appendingPathComponent("objects")
    encoder.userInfo[AttachmentSerializer.attachmentSerializerKey] = AttachmentSerializer(
      fileManager: fileManager,
      objectsDir: objectsDir)

    let data = try encoder.encode(thread)
    try fileManager.write(data: data, to: rawContentPath, options: .atomic)
  }

  func loadLastChatThreads(last: Int, offset: Int) async throws -> [ChatThreadModelMetadata] {
    let records = try await dbQueue.read { db in
      try ChatThreadRecord
        .order(Column("createdAt").desc)
        .limit(last, offset: offset)
        .fetchAll(db)
    }
    return records.map { record in
      ChatThreadModelMetadata(
        id: UUID(uuidString: record.id) ?? UUID(),
        name: record.name,
        createdAt: record.createdAt)
    }
  }

  func loadChatThread(id: UUID) async throws -> ChatThreadModel? {
    let threadRecord = try await dbQueue.read { db in
      try ChatThreadRecord.fetchOne(db, id: id.uuidString)
    }
    guard let threadRecord else { return nil }
    let task = Task.detached(priority: .userInitiated) { () -> ChatThreadModel? in
      let rawContentPath = URL(filePath: threadRecord.rawContentPath)
      let rawContent = try self.fileManager.read(dataFrom: URL(filePath: threadRecord.rawContentPath))
      let decoder = JSONDecoder()

      let objectsDir = rawContentPath.deletingLastPathComponent().appendingPathComponent("objects")
      decoder.userInfo[AttachmentSerializer.attachmentSerializerKey] = AttachmentSerializer(
        fileManager: self.fileManager,
        objectsDir: objectsDir)

      do {
        return try decoder.decode(ChatThreadModel.self, from: rawContent)
      } catch {
        defaultLogger.error("Chat thread could not be loaded. Removing it.", error)
        try await self.deleteChatThread(id: id)
        return nil
      }
    }
    return try await task.value
  }

  func deleteChatThread(id: UUID) async throws {
    _ = try await dbQueue.write { db in
      try ChatThreadRecord.deleteOne(db, id: id.uuidString)
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
      t.column("projectPath", .text)
      t.column("rawContentPath", .text)
    }

    // Create indexes for better performance
    try db.create(
      index: "chat_thread.created_at",
      on: ChatThreadRecord.databaseTableName,
      columns: ["createdAt"],
      ifNotExists: true)
  }

}

extension BaseProviding where Self: FileManagerProviding {
  public var chatHistoryService: ChatHistoryService {
    shared {
      DefaultChatHistoryService(
        createDBConnection: {
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
              try fileManager.createDirectory(
                at: chatDataURL,
                withIntermediateDirectories: true,
                attributes: nil)
            }

            let dbURL = chatDataURL.appendingPathComponent("chat.sqlite")
            let connection = try DatabaseQueue(path: dbURL.path)
            logger.log("Database initialized at: \(dbURL.path)")
            return connection
          } catch {
            logger.error("Failed to create database connection", error)
            return try! DatabaseQueue()
          }
        },
        fileManager: fileManager)
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

final class AttachmentSerializer: Sendable {
  init(fileManager: FileManagerI, objectsDir: URL) {
    self.fileManager = fileManager
    self.objectsDir = objectsDir
  }

  static let attachmentSerializerKey = CodingUserInfoKey(rawValue: "attachmentSerializer")!
  static let toolsPluginKey = CodingUserInfoKey(rawValue: "toolsPlugin")!

  func save(_ string: String, for id: UUID) throws {
    let data = Data(string.utf8)
    try save(data, for: id)
  }

  func save(_ data: Data, for id: UUID) throws {
    let objectPath = objectsDir.appendingPathComponent("\(id).json")
    try fileManager.createDirectory(
      at: objectsDir,
      withIntermediateDirectories: true,
      attributes: nil)
    return try fileManager.write(data: data, to: objectPath, options: .atomic)
  }

  func read(_: String.Type, for id: UUID) throws -> String {
    let data = try read(Data.self, for: id)
    guard let string = String(data: data, encoding: .utf8) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [],
          debugDescription: "Failed to decode string from data"))
    }
    return string
  }

  func read(_: Data.Type, for id: UUID) throws -> Data {
    let objectPath = objectsDir.appendingPathComponent("\(id).json")
    return try fileManager.read(dataFrom: objectPath)
  }

  private let fileManager: FileManagerI
  private let objectsDir: URL

}

extension Decoder {
  var attachmentSerializer: AttachmentSerializer {
    get throws {
      guard let loader = userInfo[AttachmentSerializer.attachmentSerializerKey] as? AttachmentSerializer else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "AttachmentSerializer not found in userInfo"))
      }
      return loader
    }
  }

  var toolsPlugin: ToolsPlugin {
    get throws {
      guard let plugin = userInfo[AttachmentSerializer.toolsPluginKey] as? ToolsPlugin else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "ToolsPlugin not found in userInfo"))
      }
      return plugin
    }
  }
}

extension Encoder {
  var attachmentSerializer: AttachmentSerializer {
    get throws {
      guard let loader = userInfo[AttachmentSerializer.attachmentSerializerKey] as? AttachmentSerializer else {
        throw EncodingError.invalidValue(
          self,
          EncodingError.Context(
            codingPath: codingPath,
            debugDescription: "AttachmentSerializer not found in userInfo"))
      }
      return loader
    }
  }

  var toolsPlugin: ToolsPlugin {
    get throws {
      guard let plugin = userInfo[AttachmentSerializer.toolsPluginKey] as? ToolsPlugin else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "ToolsPlugin not found in userInfo"))
      }
      return plugin
    }
  }
}

extension String {
  var sha256: String {
    let data = Data(utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02hhx", $0) }.joined()
  }
}
