// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
import AppEventServiceInterface
import AppKit
import ChatAppEvents
import ChatFoundation
import Combine
import Dependencies
import Foundation
import FoundationInterfaces
import LLMFoundation
import LLMServiceInterface
import SettingsServiceInterface
import SwiftTesting
import Testing
import XcodeObserverServiceInterface
@testable import Chat

// MARK: - ChatViewModelTests

struct ChatViewModelTests {
  let dummyAXElement = AnyAXUIElement(AXUIElementCreateApplication(0))

  @MainActor
  @Test("initializing with default parameters creates a tab with default mode")
  func test_initialization_withDefaultParameters() {
    let viewModel = ChatViewModel()

    #expect(viewModel.tabs.count == 1)
    #expect(viewModel.selectedTab == viewModel.tabs.first)
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
    let tab1 = ChatTabViewModel()
    let tab2 = ChatTabViewModel()
    let tabs = [tab1, tab2]

    let viewModel = ChatViewModel(
      defaultMode: .ask,
      tabs: tabs,
      currentModel: .gpt_4o,
      selectedTab: tab2)

    #expect(viewModel.tabs.count == 2)
    #expect(viewModel.tabs[0] == tab1)
    #expect(viewModel.tabs[1] == tab2)
    #expect(viewModel.selectedTab == tab2)
    #expect(viewModel.defaultMode == ChatMode.ask)
    #expect(viewModel.currentModel == .gpt_4o)
  }

  @MainActor
  @Test("adding a new tab increases tab count when current tab is not empty")
  func test_addTab_increasesTabCount() async {
    let viewModel = withAllModelAvailable {
      ChatViewModel()
    }
    viewModel.selectedTab?.input.textInput = TextInput([.text("Test input")])
    await viewModel.selectedTab?.sendMessage()
    #expect(viewModel.tabs.count == 1)
    viewModel.addTab()

    #expect(viewModel.tabs.count == 2)
    #expect(viewModel.selectedTab == viewModel.tabs.last)
  }

  @MainActor
  @Test("adding a new tab when current tab is empty replaces it")
  func test_addTab_replacesEmptyTab() {
    let viewModel = withAllModelAvailable {
      ChatViewModel(tabs: [.init()])
    }
    let initialTab = viewModel.tabs.first

    // Ensure the initial tab is empty
    #expect(initialTab?.events.isEmpty == true)
    #expect(viewModel.tabs.count == 1)
    viewModel.addTab()

    #expect(viewModel.tabs.count == 1)
    #expect(viewModel.selectedTab != initialTab)
  }

  @MainActor
  @Test("adding a new tab with copyingCurrentInput copies the input")
  func test_addTab_withCopyingCurrentInput() {
    let viewModel = ChatViewModel()
    let initialTab = viewModel.selectedTab

    // Set some input on the initial tab
    initialTab?.input.textInput = TextInput([.text("Test input")])

    viewModel.addTab(copyingCurrentInput: true)

    #expect(viewModel.selectedTab?.input.textInput.string.string == "Test input")
  }

  @MainActor
  @Test("removing a tab decreases tab count")
  func test_removeTab_decreasesTabCount() {
    // Create a viewModel with multiple tabs
    let tab1 = ChatTabViewModel()
    let tab2 = ChatTabViewModel()
    let tabs = [tab1, tab2]

    let viewModel = ChatViewModel(tabs: tabs)

    let initialTabCount = viewModel.tabs.count

    viewModel.remove(tab: tab2)

    #expect(viewModel.tabs.count == initialTabCount - 1)
    #expect(!viewModel.tabs.contains(tab2))
  }

  @MainActor
  @Test("removing the selected tab selects the first tab")
  func test_removeTab_removingSelectedTab() {
    // Create a viewModel with multiple tabs
    let tab1 = ChatTabViewModel()
    let tab2 = ChatTabViewModel()
    let tabs = [tab1, tab2]

    let viewModel = ChatViewModel(tabs: tabs, selectedTab: tab2)

    viewModel.remove(tab: tab2)

    #expect(viewModel.selectedTab == tab1)
  }

  @MainActor
  @Test("removing the last tab creates a new one")
  func test_removeTab_removingLastTab() throws {
    let viewModel = ChatViewModel()
    let initialTab = try #require(viewModel.tabs.first)

    #expect(viewModel.tabs.count == 1)
    viewModel.remove(tab: initialTab)

    #expect(viewModel.tabs.count == 1)
    #expect(viewModel.tabs.first != initialTab)
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

    viewModel.selectedTab?.input.textInput = TextInput([.text("Test input")])
    await viewModel.selectedTab?.sendMessage()
    #expect(viewModel.tabs.count == 1)
    #expect(viewModel.tabs.first?.events.count == 1)

    let handled = await mockAppEventHandlerRegistry.handle(event: NewChatEvent())
    #expect(handled == true)

    // Verify a new tab was added
    #expect(viewModel.tabs.count == 2)
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
    viewModel.selectedTab?.input.textInput = TextInput([.text("Test input")])
    await viewModel.selectedTab?.sendMessage()
    #expect(viewModel.tabs.count == 1)
    #expect(viewModel.tabs.first?.events.count == 1)

    let handled = await mockAppEventHandlerRegistry.handle(event: AddCodeToChatEvent(newThread: true, chatMode: .ask))
    #expect(handled == true)

    // Verify a new tab was added
    #expect(viewModel.tabs.count == 2)
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
    #expect(viewModel.selectedTab?.input.mode == .ask)
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
    #expect(viewModel.selectedTab?.input.attachments.count == 1)
    if case .file(let fileAttachment) = viewModel.selectedTab?.input.attachments.first {
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
    #expect(viewModel.selectedTab?.input.attachments.count == 1)
    if case .fileSelection(let selectionAttachment) = viewModel.selectedTab?.input.attachments.first {
      #expect(selectionAttachment.file.path == filePath)
      #expect(selectionAttachment.file.content == content)
      #expect(selectionAttachment.startLine == 1) // 0-based to 1-based
      #expect(selectionAttachment.endLine == 2) // 0-based to 1-based
    } else {
      Issue.record("Expected a file selection attachment")
    }
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
