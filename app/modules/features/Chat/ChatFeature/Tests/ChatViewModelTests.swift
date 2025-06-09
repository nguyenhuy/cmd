// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
