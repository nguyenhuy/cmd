// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CheckpointServiceInterface
import Combine
import Dependencies
import Foundation
import FoundationInterfaces
import LLMServiceInterface
import ServerServiceInterface
import SwiftTesting
import Testing
import XcodeObserverServiceInterface
@testable import Chat

// MARK: - ChatTabViewModelTests

struct ChatTabViewModelTests {

  // MARK: - Tests

  @MainActor
  @Test("View model fetches existing files on creation")
  func viewModelFetchesExistingFilesOnCreation() async throws {
    // Setup
    let workspaceURL = URL(fileURLWithPath: "/test/workspace/project.xcworkspace")
    let mockXcodeObserver = MockXcodeObserver(workspaceURL: workspaceURL)
    let mockFileManager = MockFileManager()
    let mockServer = MockServer()
    mockServer.onPostRequest = { path, _, _ in
      if path == "listFiles" {
        // Create a mock response for the listFiles endpoint
        let fileInfo = Schema.ListedFileInfo(
          path: "/test/workspace/file1.swift",
          isFile: true,
          isDirectory: false,
          isSymlink: false,
          byteSize: 100,
          permissions: "rw-r--r--",
          createdAt: "2025-01-01T00:00:00Z",
          modifiedAt: "2025-01-01T00:00:00Z")

        let response = Schema.ListFilesToolOutput(
          files: [fileInfo],
          hasMore: false)
        return try JSONEncoder().encode(response)
      }

      throw URLError(.badServerResponse)
    }
    let mockLLMService = MockLLMService()
    let mockCheckpointService = MockCheckpointService()

    // Test
    let sut = withDependencies {
      $0.xcodeObserver = mockXcodeObserver
      $0.fileManager = mockFileManager
      $0.server = mockServer
      $0.llmService = mockLLMService
      $0.checkpointService = mockCheckpointService
    } operation: {
      ChatTabViewModel()
    }

    let exp = expectation(description: "Messages updated")
    let cancellable = sut.didSet(\.messages) { _ in
      exp.fulfillAtMostOnce()
    }

    try await fulfillment(of: exp)

    // Assert
    let lastMessageContent = try #require(sut.messages.last?.content.first)
    switch lastMessageContent {
    case .nonUserFacingText(let textContent):
      #expect(textContent.text.contains("file1.swift"))
    default:
      XCTFail("Expected nonUserFacingText content")
    }
    _ = cancellable
  }
}
