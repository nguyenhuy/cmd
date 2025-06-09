// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import ChatFeatureInterface
import ChatHistoryServiceInterface
import Dependencies
import Foundation
import Testing
@testable import ChatFeature

@MainActor
struct ChatHistoryViewModelTests {

  @Test
  func testLoadInitialThreads() async throws {
    let mockThreads = [
      ChatThreadModel(
        id: UUID(),
        name: "Test Thread 1",
        messages: [],
        events: [],
        projectInfo: nil,
        createdAt: Date().addingTimeInterval(-3600)),
      ChatThreadModel(
        id: UUID(),
        name: "Test Thread 2",
        messages: [],
        events: [],
        projectInfo: nil,
        createdAt: Date()),
    ]

    let viewModel = withDependencies {
      $0.chatHistoryService = MockChatHistoryService(chatThreads: mockThreads)
    } operation: {
      ChatHistoryViewModel()
    }

    await viewModel.loadMoreThreadsIfNeeded()

    #expect(viewModel.threads.count == 2)
    #expect(viewModel.threads[0].name == "Test Thread 2") // Most recent first
    #expect(viewModel.threads[1].name == "Test Thread 1")
    #expect(!viewModel.isLoading)
  }

  @Test
  func testPagination() async throws {
    let mockThreads = Array(0..<25).map { index in
      ChatThreadModel(
        id: UUID(),
        name: "Thread \(index)",
        messages: [],
        events: [],
        projectInfo: nil,
        createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600)))
    }

    let viewModel = withDependencies {
      $0.chatHistoryService = MockChatHistoryService(chatThreads: mockThreads)
    } operation: {
      ChatHistoryViewModel()
    }

    await viewModel.loadMoreThreadsIfNeeded()

    #expect(viewModel.threads.count == 20) // First page
    #expect(viewModel.hasMoreThreads)

    await viewModel.loadMoreThreadsIfNeeded()

    #expect(viewModel.threads.count == 25) // All threads loaded
    #expect(!viewModel.hasMoreThreads)
  }
}
