// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppEventServiceInterface
import ChatAppEvents
import ChatFoundation
import ChatHistoryServiceInterface
import Combine
import Dependencies
import Foundation
import FoundationInterfaces
import LLMFoundation
import LoggingServiceInterface
import Observation
import SwiftUI
import XcodeObserverServiceInterface

// MARK: - ChatViewModel

@MainActor @Observable
public class ChatViewModel {

  #if DEBUG
  convenience init(
    defaultMode: ChatMode? = nil,
    tabs: [ChatTabViewModel],
    currentModel: LLMModel = .claudeSonnet_4_0,
    selectedTab: ChatTabViewModel? = nil)
  {
    self.init(
      defaultMode: defaultMode ?? .agent,
      tabs: tabs,
      currentModel: currentModel,
      selectedTab: selectedTab ?? tabs.first)
  }
  #endif

  public convenience init(defaultMode: ChatMode? = nil) {
    let tabs = [ChatTabViewModel()]
    self.init(
      defaultMode: defaultMode ?? .agent,
      tabs: tabs,
      currentModel: .claudeSonnet_4_0,
      selectedTab: tabs.first)
  }

  private init(
    defaultMode: ChatMode,
    tabs: [ChatTabViewModel],
    currentModel: LLMModel,
    selectedTab: ChatTabViewModel?)
  {
    self.tabs = tabs
    self.currentModel = currentModel
    self.selectedTab = selectedTab
    self.defaultMode = defaultMode
    registerAsAppEventHandler()

    xcodeObserver.statePublisher.map(\.focusedWorkspace).map(\.?.url).removeDuplicates()
      .sink { @Sendable [weak self] focusedWorkspacePath in
        Task { @MainActor in
          self?.focusedWorkspacePath = focusedWorkspacePath
        }
      }.store(in: &cancellables)

    Task {
      await loadPersistedChatThreads()
    }
  }

  var tabs: [ChatTabViewModel]
  var currentModel: LLMModel
  var selectedFile: URL?
  var selectedTab: ChatTabViewModel?
  // TODO: persist to user defaults and load
  var defaultMode: ChatMode
  private(set) var focusedWorkspacePath: URL? = nil

  @ObservationIgnored @Dependency(\.chatHistoryService) var chatHistoryService: ChatHistoryService

  /// Create a new tab/thread.
  /// - Parameter copyingCurrentInput: Whether the current input content should be ported to the new tab.
  func addTab(copyingCurrentInput: Bool = false) {
    let newTab = ChatTabViewModel()
    let currentTab = selectedTab
    if selectedTab?.events.isEmpty == true {
      // if the selected tab is empty, replace it with the new tab instead of keeping it in memory.
      tabs[tabs.count - 1] = newTab
    } else {
      tabs.append(newTab)
    }
    selectedTab = newTab
    if copyingCurrentInput, let currentTab {
      newTab.input = currentTab.input.copy()
    }
  }

  func remove(tab: ChatTabViewModel) {
    tabs.removeAll { $0 == tab }
    if selectedTab == tab {
      selectedTab = tabs.first
    }
    if tabs.isEmpty {
      addTab()
    }
  }

  // MARK: - Persistence Methods

  func loadPersistedChatThreads() async {
    do {
      guard
        let persistentTabInfo = try await chatHistoryService.loadLastChatThreads(last: 1, offset: 0).first,
        let thread = try await chatHistoryService.loadChatThread(id: persistentTabInfo.id)
      else {
        return
      }
      let chatTab = ChatTabViewModel(from: thread)

      tabs = [chatTab]
      selectedTab = chatTab

      defaultLogger.log("Loaded chat tabs from database")
    } catch {
      defaultLogger.error("Failed to load chat tabs from database", error)
    }
  }

  @ObservationIgnored private var cancellables = Set<AnyCancellable>()

  @ObservationIgnored @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry
  @ObservationIgnored @Dependency(\.xcodeObserver) private var xcodeObserver
  @ObservationIgnored @Dependency(\.fileManager) private var fileManager

  private func registerAsAppEventHandler() {
    appEventHandlerRegistry.registerHandler { [weak self] event in
      guard let self else { return false }
      if let event = event as? AddCodeToChatEvent {
        await handle(addCodeToChatEvent: event)
        return true //
      } else if let event = event as? ChangeChatModeEvent {
        Task { @MainActor in
          self.selectedTab?.input.mode = event.chatMode
        }
        return true
      } else if event is NewChatEvent {
        await addTab(copyingCurrentInput: true)
        return true
      } else {
        return false
      }
    }
  }

  private func handle(addCodeToChatEvent event: AddCodeToChatEvent) {
    Task { @MainActor in
      if !["swiftpm-testing-helper", "xctest"].contains(ProcessInfo.processInfo.processName) {
        NSApp.setActivationPolicy(.regular)
        // TODO: make sure the app is activated. Sometimes it doesn't work.
        Task { try await NSApplication.activateCurrentApp() }
      }

      if event.newThread {
        self.addTab()
      }
      if let chatMode = event.chatMode {
        self.selectedTab?.input.mode = chatMode
      }

      self.selectedTab?.input.textInputNeedsFocus = true

      if let workspace = xcodeObserver.state.focusedWorkspace {
        let handled = addCodeSelection(from: workspace)
        if !handled {
          // Add log for debugging.
          if
            let axInfo = xcodeObserver.state.wrapped?.xcodesState.first?.workspaces.first?.axElement.wrappedValue?
              .debugDescription
          {
            defaultLogger.log(axInfo as String)
          }
        }
      } else {
        defaultLogger.log("No workspace found to handle add to code to chat event")
      }
    }
  }

  private func addCodeSelection(from workspace: XcodeWorkspaceState) -> Bool {
    guard let inputModel = selectedTab?.input else {
      defaultLogger.log("Missing selected Tab to handle add to code to chat event")
      return false
    }
    let editor = workspace.editors.first(where: { $0.isFocused })
    if editor?.fileName != workspace.document?.lastPathComponent {
      if let document = workspace.document, let content = try? fileManager.read(contentsOf: document) {
        inputModel.add(attachment: .file(.init(path: document, content: content)))
        return true
      }
    }
    guard let editor else {
      defaultLogger.log("No editor found to handle add to code to chat event")
      return false
    }

    let content = editor.content
    guard !content.isEmpty else {
      defaultLogger.log("No content found in the focus editor to handle add to code to chat event")
      return false
    }
    guard let filePath = workspace.tabs.first(where: { $0.fileName == editor.fileName })?.knownPath else {
      defaultLogger.log("Could not resolve file path for file \(editor.fileName) to handle add to code to chat event")
      return false
    }
    if let selection = editor.selections.first, selection.start != selection.end {
      inputModel.add(attachment: .fileSelection(.init(
        file: .init(path: filePath, content: content),
        startLine: selection.start.line + 1,
        endLine: selection.end.line + 1)))
    } else {
      inputModel.add(attachment: .file(.init(path: filePath, content: content)))
    }
    return true
  }

}

extension NSApplication {
  static func activateCurrentApp() async throws {
    NSApplication.shared.activate(ignoringOtherApps: true)
    let activated = NSRunningApplication.current.activate()
    if activated { return }
    let appleScript = """
      tell application "System Events"
          set frontmost of the first process whose unix id is \
      \(ProcessInfo.processInfo.processIdentifier) to true
      end tell
      """
    try await runAppleScript(appleScript)
  }

  @discardableResult
  static func runAppleScript(_ appleScript: String) async throws -> String {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", appleScript]
    let outpipe = Pipe()
    task.standardOutput = outpipe
    task.standardError = Pipe()

    return try await withUnsafeThrowingContinuation { continuation in
      do {
        task.terminationHandler = { _ in
          do {
            if
              let data = try outpipe.fileHandleForReading.readToEnd(),
              let content = String(data: data, encoding: .utf8)
            {
              continuation.resume(returning: content)
              return
            }
            continuation.resume(returning: "")
          } catch {
            continuation.resume(throwing: error)
          }
        }
        try task.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
