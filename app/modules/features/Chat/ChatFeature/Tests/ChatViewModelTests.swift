// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AccessibilityFoundation
import AppEventServiceInterface
import AppKit
import ChatAppEvents
import ChatFeatureInterface
import ChatFoundation
import ChatHistoryServiceInterface
import Combine
import ConcurrencyFoundation
import Dependencies
import Foundation
import FoundationInterfaces
import LLMFoundation
import LLMServiceInterface
import SettingsServiceInterface
import SwiftTesting
import Testing
import XcodeObserverServiceInterface
@testable import ChatFeature

// MARK: - ChatViewModelTests

struct ChatViewModelTests {
  let dummyAXElement = AnyAXUIElement(AXUIElementCreateApplication(0))

  @MainActor
  @Test("initializing with default parameters creates a tab with default mode")
  func test_initialization_withDefaultParameters() {
    let viewModel = ChatViewModel()

    #expect(viewModel.tab.messages == [])
    #expect(viewModel.defaultMode == .agent)
    #expect(viewModel.currentModel == .claudeSonnet_4_0)
  }

  @MainActor
  @Test("initializing with custom mode uses that mode")
  func test_initialization_withCustomMode() {
    let viewModel = ChatViewModel(defaultMode: .ask)

    #expect(viewModel.defaultMode == ChatMode.ask)
  }

  @MainActor
  @Test("debug initializer with custom tabs and selected tab")
  func test_debugInitializer_withCustomTabsAndSelectedTab() {
    let tab = ChatTabViewModel()

    let viewModel = ChatViewModel(
      defaultMode: .ask,
      tab: tab)

    #expect(viewModel.tab == tab)
    #expect(viewModel.defaultMode == ChatMode.ask)
    #expect(viewModel.currentModel == .claudeSonnet_4_0)
  }

  @MainActor
  @Test("adding a new tab replaces the current one")
  func test_addTab_increasesTabCount() async {
    let viewModel = withAllModelAvailable {
      ChatViewModel()
    }
    let firstTab = viewModel.tab
    firstTab.input.textInput = TextInput([.text("Test input")])
    await firstTab.sendMessage()
    #expect(viewModel.tab.messages.count == 1)
    viewModel.addTab()

    #expect(viewModel.tab.messages.count == 0)
    #expect(viewModel.tab != firstTab)
  }

  @MainActor
  @Test("adding a new tab with copyingCurrentInput copies the input")
  func test_addTab_withCopyingCurrentInput() {
    let viewModel = ChatViewModel()
    let initialTab = viewModel.tab

    // Set some input on the initial tab
    initialTab.input.textInput = TextInput([.text("Test input")])

    viewModel.addTab(copyingCurrentInput: true)

    #expect(viewModel.tab != initialTab)
    #expect(viewModel.tab.input.textInput.string.string == "Test input")
  }

  @MainActor
  @Test("handling NewChatEvent adds a new tab")
  func test_handleNewChatEvent() async {
    let mockAppEventHandlerRegistry = MockAppEventHandlerRegistry()

    let viewModel = withAllModelAvailable {
      withDependencies {
        $0.appEventHandlerRegistry = mockAppEventHandlerRegistry
      } operation: {
        ChatViewModel()
      }
    }

    let firstTab = viewModel.tab
    firstTab.input.textInput = TextInput([.text("Test input")])
    await firstTab.sendMessage()
    #expect(firstTab.events.count == 1)

    let handled = await mockAppEventHandlerRegistry.handle(event: NewChatEvent())
    #expect(handled == true)

    // Verify a new tab was added
    #expect(viewModel.tab != firstTab)
  }

  @MainActor
  @Test("handling AddCodeToChatEvent with newThread creates a new tab")
  func test_handleAddCodeToChatEvent_withNewThread() async {
    let mockAppEventHandlerRegistry = MockAppEventHandlerRegistry()
    let mockXcodeObserver = MockXcodeObserver(AXState<XcodeState>.unknown)

    let viewModel = withAllModelAvailable { withDependencies {
      $0.appEventHandlerRegistry = mockAppEventHandlerRegistry
      $0.xcodeObserver = mockXcodeObserver
    } operation: {
      ChatViewModel()
    }
    }
    let firstTab = viewModel.tab
    firstTab.input.textInput = TextInput([.text("Test input")])
    await firstTab.sendMessage()
    #expect(firstTab.events.count == 1)

    let handled = await mockAppEventHandlerRegistry.handle(event: AddCodeToChatEvent(newThread: true, chatMode: .ask))
    #expect(handled == true)

    // Verify a new tab was added
    #expect(viewModel.tab != firstTab)
  }

  @MainActor
  @Test("handling AddCodeToChatEvent with chatMode updates the selected tab's mode")
  func test_handleAddCodeToChatEvent_withChatMode() async {
    let mockAppEventHandlerRegistry = MockAppEventHandlerRegistry()
    let mockXcodeObserver = MockXcodeObserver(AXState<XcodeState>.unknown)

    let viewModel = withDependencies {
      $0.appEventHandlerRegistry = mockAppEventHandlerRegistry
      $0.xcodeObserver = mockXcodeObserver
    } operation: {
      ChatViewModel()
    }

    let handled = await mockAppEventHandlerRegistry.handle(event: AddCodeToChatEvent(newThread: false, chatMode: .ask))
    #expect(handled == true)

    // Verify the selected tab's mode was updated
    #expect(viewModel.tab.input.mode == .ask)
  }

  @MainActor
  @Test("addCodeSelection adds file attachment when no editor is focused")
  func test_addCodeSelection_addsFileAttachment() async throws {
    let documentURL = try #require(URL(string: "file:///test/file.swift"))
    let documentContent = "Test file content"
    let mockFileManager = MockFileManager(files: [
      documentURL.path(): documentContent,
    ])
    let mockAppEventHandlerRegistry = MockAppEventHandlerRegistry()

    let xcodeState = XcodeState(
      activeApplicationProcessIdentifier: 123,
      previousApplicationProcessIdentifier: nil,
      xcodesState: [
        XcodeAppState(
          processIdentifier: 123,
          isActive: true,
          workspaces: [XcodeWorkspaceState(
            axElement: dummyAXElement,
            url: URL(string: "file:///test/project.xcodeproj")!,
            editors: [],
            isFocused: true,
            document: documentURL,
            tabs: [])]),
      ])
    let mockXcodeObserver = MockXcodeObserver(AXState<XcodeState>.state(xcodeState))

    let viewModel = withDependencies {
      $0.xcodeObserver = mockXcodeObserver
      $0.fileManager = mockFileManager
      $0.appEventHandlerRegistry = mockAppEventHandlerRegistry
    } operation: {
      ChatViewModel()
    }

    // Call the method through the event handler
    let handled = await mockAppEventHandlerRegistry.handle(event: AddCodeToChatEvent(newThread: false, chatMode: nil))
    #expect(handled)
    // Verify a file attachment was added
    #expect(viewModel.tab.input.attachments.count == 1)
    if case .file(let fileAttachment) = viewModel.tab.input.attachments.first {
      #expect(fileAttachment.path == documentURL)
      #expect(fileAttachment.content == documentContent)
    } else {
      Issue.record("Expected a file attachment")
    }
  }

  @MainActor
  @Test("addCodeSelection adds file selection attachment when editor has selection")
  func test_addCodeSelection_addsFileSelectionAttachment() async throws {
    let filePath = try #require(URL(string: "file:///test/file.swift"))
    let content = "Test file content"
    let mockFileManager = MockFileManager(files: [
      filePath.path(): content,
    ])
    let mockAppEventHandlerRegistry = MockAppEventHandlerRegistry()

    let xcodeState = XcodeState(
      activeApplicationProcessIdentifier: 123,
      previousApplicationProcessIdentifier: nil,
      xcodesState: [
        XcodeAppState(
          processIdentifier: 123,
          isActive: true,
          workspaces: [XcodeWorkspaceState(
            axElement: dummyAXElement,
            url: URL(string: "file:///test/project.xcodeproj")!,
            editors: [XcodeEditorState(
              fileName: filePath.lastPathComponent,
              isFocused: true,
              content: content,
              selections: [CursorRange(start: CursorPosition(line: 0, character: 0), end: CursorPosition(line: 1, character: 5))],
              compilerMessages: [])],
            isFocused: true,
            document: filePath,
            tabs: [XcodeWorkspaceState.Tab(
              fileName: "file.swift",
              isFocused: true,
              knownPath: filePath,
              lastKnownContent: content)])]),
      ])
    let mockXcodeObserver = MockXcodeObserver(AXState<XcodeState>.state(xcodeState))

    let viewModel = withDependencies {
      $0.xcodeObserver = mockXcodeObserver
      $0.fileManager = mockFileManager
      $0.appEventHandlerRegistry = mockAppEventHandlerRegistry
    } operation: {
      ChatViewModel()
    }

    let handled = await mockAppEventHandlerRegistry.handle(event: AddCodeToChatEvent(newThread: false, chatMode: nil))
    #expect(handled)

    // Verify a file selection attachment was added
    #expect(viewModel.tab.input.attachments.count == 1)
    if case .fileSelection(let selectionAttachment) = viewModel.tab.input.attachments.first {
      #expect(selectionAttachment.file.path == filePath)
      #expect(selectionAttachment.file.content == content)
      #expect(selectionAttachment.startLine == 1) // 0-based to 1-based
      #expect(selectionAttachment.endLine == 2) // 0-based to 1-based
    } else {
      Issue.record("Expected a file selection attachment")
    }
  }

  // MARK: - Chat History Tests

  @MainActor
  @Test("loadPersistedChatThreads loads the most recent thread")
  func test_loadPersistedChatThreads_loadsRecentThread() async {
    let threadId = UUID()
    let testThread = ChatThreadModel(
      id: threadId,
      name: "Test Thread",
      messages: [],
      events: [],
      projectInfo: nil,
      createdAt: Date())

    let mockChatHistoryService = MockChatHistoryService(chatThreads: [testThread])

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    await viewModel.loadPersistedChatThreads()

    #expect(viewModel.tab.id == threadId)
    #expect(viewModel.tab.name == "Test Thread")
  }

  @MainActor
  @Test("loadPersistedChatThreads handles empty history gracefully")
  func test_loadPersistedChatThreads_handlesEmptyHistory() async {
    let mockChatHistoryService = MockChatHistoryService(chatThreads: [])

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    let originalTabId = viewModel.tab.id
    await viewModel.loadPersistedChatThreads()

    // Should keep the original tab when no persisted threads exist
    #expect(viewModel.tab.id == originalTabId)
  }

  @MainActor
  @Test("loadPersistedChatThreads handles service errors gracefully")
  func test_loadPersistedChatThreads_handlesErrors() async {
    let mockChatHistoryService = MockChatHistoryService()
    mockChatHistoryService.onLoadLastChatThreads = { _, _ in
      throw NSError(domain: "TestError", code: 1, userInfo: nil)
    }

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    let originalTabId = viewModel.tab.id
    await viewModel.loadPersistedChatThreads()

    // Should keep the original tab when loading fails
    #expect(viewModel.tab.id == originalTabId)
  }

  @MainActor
  @Test("handleSelectChatThread loads and switches to selected thread")
  func test_handleSelectChatThread_loadsAndSwitches() async {
    let threadId = UUID()
    let testThread = ChatThreadModel(
      id: threadId,
      name: "Selected Thread",
      messages: [],
      events: [],
      projectInfo: nil,
      createdAt: Date())

    let mockChatHistoryService = MockChatHistoryService(chatThreads: [testThread])

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    viewModel.handleShowChatHistory()
    #expect(viewModel.showChatHistory == true)

    viewModel.handleSelectChatThread(id: threadId)

    // Wait for async operation to complete
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    #expect(viewModel.tab.id == threadId)
    #expect(viewModel.tab.name == "Selected Thread")
    #expect(viewModel.showChatHistory == false)
  }

  @MainActor
  @Test("handleSelectChatThread handles missing thread gracefully")
  func test_handleSelectChatThread_handlesMissingThread() async throws {
    let mockChatHistoryService = MockChatHistoryService(chatThreads: [])

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    let originalTabId = viewModel.tab.id
    viewModel.handleShowChatHistory()
    #expect(viewModel.showChatHistory == true)

    let didChangeShowChatHistory = expectation(description: "didChangeShowChatHistory")
    let cancellable = viewModel.didSet(\.showChatHistory, perform: { _ in
      didChangeShowChatHistory.fulfill()
    })

    viewModel.handleSelectChatThread(id: UUID())

    try await fulfillment(of: didChangeShowChatHistory)

    // Should keep original tab and hide chat history
    #expect(viewModel.tab.id == originalTabId)
    #expect(viewModel.showChatHistory == false)
    _ = cancellable
  }

  @MainActor
  @Test("handleSelectChatThread handles service errors gracefully")
  func test_handleSelectChatThread_handlesErrors() async {
    let mockChatHistoryService = MockChatHistoryService()
    mockChatHistoryService.onLoadChatThread = { _ in
      throw NSError(domain: "TestError", code: 1, userInfo: nil)
    }

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    let originalTabId = viewModel.tab.id
    viewModel.handleShowChatHistory()
    #expect(viewModel.showChatHistory == true)

    viewModel.handleSelectChatThread(id: UUID())

    // Wait for async operation to complete
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    // Should keep original tab and hide chat history
    #expect(viewModel.tab.id == originalTabId)
    #expect(viewModel.showChatHistory == false)
  }

  @MainActor
  @Test("handleShowChatHistory sets showChatHistory to true")
  func test_handleShowChatHistory() {
    let viewModel = ChatViewModel()

    #expect(viewModel.showChatHistory == false)

    viewModel.handleShowChatHistory()

    #expect(viewModel.showChatHistory == true)
  }

  @MainActor
  @Test("handleHideChatHistory sets showChatHistory to false")
  func test_handleHideChatHistory() {
    let viewModel = ChatViewModel()
    viewModel.handleShowChatHistory()

    #expect(viewModel.showChatHistory == true)

    viewModel.handleHideChatHistory()

    #expect(viewModel.showChatHistory == false)
  }

  @MainActor
  @Test("chat history integration with multiple threads")
  func test_chatHistoryIntegration_multipleThreads() async {
    let thread1Id = UUID()
    let thread2Id = UUID()
    let thread1 = ChatThreadModel(
      id: thread1Id,
      name: "Thread 1",
      messages: [],
      events: [],
      projectInfo: nil,
      createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
    )
    let thread2 = ChatThreadModel(
      id: thread2Id,
      name: "Thread 2",
      messages: [],
      events: [],
      projectInfo: nil,
      createdAt: Date(), // now
    )

    let mockChatHistoryService = MockChatHistoryService(chatThreads: [thread1, thread2])

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    // Load persisted threads (should load most recent)
    await viewModel.loadPersistedChatThreads()
    #expect(viewModel.tab.id == thread2Id)
    #expect(viewModel.tab.name == "Thread 2")

    // Switch to older thread
    viewModel.handleSelectChatThread(id: thread1Id)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    #expect(viewModel.tab.id == thread1Id)
    #expect(viewModel.tab.name == "Thread 1")

    // Switch back to newer thread
    viewModel.handleSelectChatThread(id: thread2Id)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    #expect(viewModel.tab.id == thread2Id)
    #expect(viewModel.tab.name == "Thread 2")
  }

  @MainActor
  @Test("chat history service interactions are called correctly")
  func test_chatHistoryServiceInteractions() async {
    let loadLastChatThreadsCalled = Atomic(false)
    let loadChatThreadCalled = Atomic(false)
    let loadChatThreadId = Atomic<UUID?>(nil)

    let threadId = UUID()
    let testThread = ChatThreadModel(
      id: threadId,
      name: "Test Thread",
      messages: [],
      events: [],
      projectInfo: nil,
      createdAt: Date())

    let mockChatHistoryService = MockChatHistoryService(chatThreads: [testThread])
    mockChatHistoryService.onLoadLastChatThreads = { last, offset in
      loadLastChatThreadsCalled.set(to: true)
      #expect(last == 1)
      #expect(offset == 0)
    }
    mockChatHistoryService.onLoadChatThread = { id in
      loadChatThreadCalled.set(to: true)
      loadChatThreadId.set(to: id)
    }

    let viewModel = withDependencies {
      $0.chatHistoryService = mockChatHistoryService
    } operation: {
      ChatViewModel()
    }

    // Test loadPersistedChatThreads
    await viewModel.loadPersistedChatThreads()
    #expect(loadLastChatThreadsCalled.value == true)

    // Test handleSelectChatThread
    viewModel.handleSelectChatThread(id: threadId)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    #expect(loadChatThreadCalled.value == true)
    #expect(loadChatThreadId.value == threadId)
  }

  /// Setup the settings and used default to allow for messages to be sent (there need to be an LLM model configured).
  private func withAllModelAvailable<R>(
    operation: () -> R)
    -> R
  {
    let settingsService = MockSettingsService.allConfigured
    let mockUserDefaults = MockUserDefaults(initialValues: [
      "selectedLLMModel": "gpt-4o",
    ])
    return withDependencies({
      $0.settingsService = settingsService
      $0.userDefaults = mockUserDefaults
    }) {
      operation()
    }
  }
}
