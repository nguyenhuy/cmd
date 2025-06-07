// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatHistoryServiceInterface
import Foundation
import SwiftTesting
import Testing
@testable import ChatFeature

// MARK: - SimplePersistenceTests

struct SimplePersistenceTests {

  @MainActor
  @Test("test model creation and conversion")
  func testModelCreationAndConversion() async {
    // Test ChatTabViewModel to ChatThreadModel conversion
    let originalTab = ChatTabViewModel(name: "Test Tab")
    let persistentModel = originalTab.persistentModel

    #expect(persistentModel.name == "Test Tab")
    #expect(persistentModel.id == originalTab.id.uuidString)

    // Test ChatThreadModel to ChatTabViewModel conversion
    let loadedTab = await ChatTabViewModel(from: persistentModel)
    #expect(loadedTab.name == "Test Tab")
    #expect(loadedTab.messages.isEmpty)
    #expect(loadedTab.events.isEmpty)
  }

  @MainActor
  @Test("test chat message model conversion")
  func testChatMessageModelConversion() {
    let textContent = ChatMessageTextContent(text: "Hello world", isStreaming: false)
    let message = ChatMessage(content: [.text(textContent)], role: .user)

    // Convert to persistent model
    let persistentMessage = message.persistentModel(for: "test-tab-id")
    #expect(persistentMessage.role == "user")
    #expect(persistentMessage.contents.count == 1)

    // Test content conversion
    let persistentContent = persistentMessage.contents.first!
    #expect(persistentContent.type == "text")
    #expect(persistentContent.text == "Hello world")
    #expect(persistentContent.isStreaming == false)
  }

  @MainActor
  @Test("test attachment model conversion")
  func testAttachmentModelConversion() {
    let fileAttachment = Attachment.FileAttachment(path: URL(filePath: "/test/file.swift"), content: "print(\"Hello\")")
    let attachment = Attachment.file(fileAttachment)

    let persistentAttachment = attachment.persistentModel
    #expect(persistentAttachment.type == "file")
    #expect(persistentAttachment.filePath == "/test/file.swift")
    #expect(persistentAttachment.fileContent == "print(\"Hello\")")
  }
}
