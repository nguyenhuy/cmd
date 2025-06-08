// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
import ChatHistoryServiceInterface
import ConcurrencyFoundation
import Foundation
import FoundationInterfaces
import GRDB
import LLMServiceInterface
import SwiftTesting
import Testing
import ToolFoundation
@testable import ChatHistoryService

// MARK: - DefaultChatHistoryServiceTests

struct DefaultChatHistoryServiceTests {

  @Test("Initializes and creates tables")
  func test_initialization() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()

    // Test
    _ = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    // Wait for database initialization
    try await Task.sleep(for: .milliseconds(100))

    // Verify tables are created
    let tableExists = try await dbQueue.read { db in
      try db.tableExists("chat_threads")
    }
    #expect(tableExists == true)
  }

  @Test("Saves and loads chat thread")
  func test_saveChatThread() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    let thread = createTestChatThread()

    // Test save
    try await service.save(chatThread: thread)

    // Verify thread was saved to database
    let record = try await dbQueue.read { db in
      try ChatThreadRecord.fetchOne(db, id: thread.id.uuidString)
    }

    #expect(record?.id == thread.id.uuidString)
    #expect(record?.name == thread.name)
    #expect(record?.createdAt == thread.createdAt)

    // Verify content file was created
    let contentPath = URL(filePath: record!.rawContentPath)
    #expect(fileManager.fileExists(atPath: contentPath.path))
  }

  @Test("Loads saved chat thread")
  func test_loadChatThread() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    let originalThread = createTestChatThread()

    // Save thread
    try await service.save(chatThread: originalThread)

    // Test load
    let loadedThread = try await service.loadChatThread(id: originalThread.id)

    // Verify
    #expect(loadedThread != nil)
    #expect(loadedThread?.id == originalThread.id)
    #expect(loadedThread?.name == originalThread.name)
    #expect(loadedThread?.createdAt == originalThread.createdAt)
    #expect(loadedThread?.messages.count == originalThread.messages.count)
  }

  @Test("Loads last chat threads with pagination")
  func test_loadLastChatThreads() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    // Create and save multiple threads
    let thread1 = createTestChatThread(name: "Thread 1")
    let thread2 = createTestChatThread(name: "Thread 2")
    let thread3 = createTestChatThread(name: "Thread 3")

    try await service.save(chatThread: thread1)
    try await service.save(chatThread: thread2)
    try await service.save(chatThread: thread3)

    // Test loading last 2 threads
    let metadata = try await service.loadLastChatThreads(last: 2, offset: 0)

    // Verify (should be ordered by creation date desc)
    #expect(metadata.count == 2)
    #expect(metadata[0].name == "Thread 3")
    #expect(metadata[1].name == "Thread 2")

    // Test pagination
    let nextMetadata = try await service.loadLastChatThreads(last: 2, offset: 2)
    #expect(nextMetadata.count == 1)
    #expect(nextMetadata[0].name == "Thread 1")
  }

  @Test("Deletes chat thread")
  func test_deleteChatThread() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    let thread = createTestChatThread()

    // Save thread
    try await service.save(chatThread: thread)

    // Verify it exists
    let existingThread = try await service.loadChatThread(id: thread.id)
    #expect(existingThread != nil)

    // Test delete
    try await service.deleteChatThread(id: thread.id)

    // Verify it's deleted
    let deletedThread = try await service.loadChatThread(id: thread.id)
    #expect(deletedThread == nil)

    // Verify database record is deleted
    let record = try await dbQueue.read { db in
      try ChatThreadRecord.fetchOne(db, id: thread.id.uuidString)
    }
    #expect(record == nil)
  }

  @Test("Handles loading non-existent thread")
  func test_loadNonExistentThread() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    // Test loading non-existent thread
    let nonExistentId = UUID()
    let thread = try await service.loadChatThread(id: nonExistentId)

    // Verify
    #expect(thread == nil)
  }

  @Test("Handles empty chat history")
  func test_emptyHistory() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    // Test loading from empty database
    let metadata = try await service.loadLastChatThreads(last: 10, offset: 0)

    // Verify
    #expect(metadata.isEmpty)
  }

  @Test("Saves multiple chat threads with different projects")
  func test_multipleThreadsWithProjects() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    // Create threads with different project info
    let projectInfo1 = ChatThreadModel.SelectedProjectInfo(
      path: URL(filePath: "/project1/Project1.xcworkspace"),
      dirPath: URL(filePath: "/project1"))
    let projectInfo2 = ChatThreadModel.SelectedProjectInfo(
      path: URL(filePath: "/project2/Project2.xcworkspace"),
      dirPath: URL(filePath: "/project2"))

    let thread1 = createTestChatThread(name: "Project 1 Thread", projectInfo: projectInfo1)
    let thread2 = createTestChatThread(name: "Project 2 Thread", projectInfo: projectInfo2)
    let thread3 = createTestChatThread(name: "No Project Thread", projectInfo: nil)

    // Save threads
    try await service.save(chatThread: thread1)
    try await service.save(chatThread: thread2)
    try await service.save(chatThread: thread3)

    // Load and verify
    let loadedThread1 = try await service.loadChatThread(id: thread1.id)
    let loadedThread2 = try await service.loadChatThread(id: thread2.id)
    let loadedThread3 = try await service.loadChatThread(id: thread3.id)

    #expect(loadedThread1?.projectInfo?.dirPath == projectInfo1.dirPath)
    #expect(loadedThread2?.projectInfo?.dirPath == projectInfo2.dirPath)
    #expect(loadedThread3?.projectInfo == nil)
  }

  @Test("Updates existing chat thread")
  func test_updateChatThread() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    let originalThread = createTestChatThread(name: "Original Name")

    // Save original thread
    try await service.save(chatThread: originalThread)

    // Create updated thread with same ID but different content
    let updatedMessages = originalThread.messages + [
      createTestMessage(content: .text(createTestTextContent(text: "New message"))),
    ]
    let updatedThread = ChatThreadModel(
      id: originalThread.id,
      name: "Updated Name",
      messages: updatedMessages,
      events: originalThread.events,
      projectInfo: originalThread.projectInfo,
      createdAt: originalThread.createdAt)

    // Save updated thread
    try await service.save(chatThread: updatedThread)

    // Load and verify
    let loadedThread = try await service.loadChatThread(id: originalThread.id)
    #expect(loadedThread?.name == "Updated Name")
    #expect(loadedThread?.messages.count == updatedMessages.count)
  }

  @Test("Handles corrupted content file")
  func test_corruptedContentFile() async throws {
    // Setup
    let (fileManager, toolsPlugin, dbQueue) = createTestComponents()
    let service = DefaultChatHistoryService(
      createDBConnection: { dbQueue },
      fileManager: fileManager,
      toolsPlugin: toolsPlugin)

    let thread = createTestChatThread()

    // Save thread
    try await service.save(chatThread: thread)

    // Get the content path and corrupt the file
    let record = try await dbQueue.read { db in
      try ChatThreadRecord.fetchOne(db, id: thread.id.uuidString)
    }
    let contentPath = URL(filePath: record!.rawContentPath)

    // Write corrupted data
    try fileManager.write(data: Data("corrupted".utf8), to: contentPath, options: .atomic)

    // Test loading corrupted thread
    let loadedThread = try await service.loadChatThread(id: thread.id)

    // Should return nil and clean up the corrupted thread
    #expect(loadedThread == nil)

    // Verify thread was deleted from database
    let deletedRecord = try await dbQueue.read { db in
      try ChatThreadRecord.fetchOne(db, id: thread.id.uuidString)
    }
    #expect(deletedRecord == nil)
  }
}

// MARK: - Test Helpers

private func createTestComponents() -> (MockFileManager, ToolsPlugin, DatabaseQueue) {
  let fileManager = MockFileManager()
  let toolsPlugin = ToolsPlugin()
  let dbQueue = try! DatabaseQueue()
  return (fileManager, toolsPlugin, dbQueue)
}

private func createTestChatThread(
  name: String = "Test Thread",
  projectInfo: ChatThreadModel.SelectedProjectInfo? = nil)
  -> ChatThreadModel
{
  let messages = [
    createTestMessage(role: .user, content: .text(createTestTextContent(text: "Hello"))),
    createTestMessage(role: .assistant, content: .text(createTestTextContent(text: "Hi there!"))),
  ]

  return ChatThreadModel(
    id: UUID(),
    name: name,
    messages: messages,
    events: [],
    projectInfo: projectInfo,
    createdAt: Date())
}

private func createTestMessage(
  role: MessageRole = .assistant,
  content: ChatMessageContentModel)
  -> ChatMessageModel
{
  ChatMessageModel(
    id: UUID(),
    content: [content],
    role: role,
    timestamp: Date())
}

private func createTestTextContent(text: String) -> ChatMessageTextContentModel {
  ChatMessageTextContentModel(
    id: UUID(),
    projectRoot: nil,
    text: text,
    attachments: [])
}
