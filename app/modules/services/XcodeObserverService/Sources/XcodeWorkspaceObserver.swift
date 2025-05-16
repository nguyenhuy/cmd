// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
import AppKit
@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation
import ThreadSafe
import XcodeObserverServiceInterface

// MARK: - XcodeWorkspaceObserver

@ThreadSafe
final class XcodeWorkspaceObserver: AXElementObserver, @unchecked Sendable {
  @MainActor
  init(runningApplication: NSRunningApplication, workspace: AXUIElement, url: URL) {
    self.runningApplication = runningApplication
    self.workspace = workspace
    workspaceURL = url
    let state = InternalXcodeWorkspaceState(
      axElement: AnyAXUIElement(workspace),
      url: workspaceURL,
      document: workspace.documentURL,
      tabs: [],
      editors: [],
      focusedTabName: nil,
      focusedEditorId: nil)
    internalState = CurrentValueSubject<InternalXcodeWorkspaceState, Never>(state)

    super.init(element: workspace)

    refresh()
  }

  let workspaceURL: URL
  var editorInspectors = [SourceEditorObserver]()

  let workspace: AXUIElement

  var state: ReadonlyCurrentValueSubject<InternalXcodeWorkspaceState, Never> {
    .init(internalState.value, publisher: internalState.eraseToAnyPublisher())
  }

  /// Parse the workspace AX tree. Ensure that we are observing any visible editor, and collect tab information.
  @MainActor
  func refresh() {
    guard let editorArea = workspace.firstChild(where: { $0.description == "editor area" }) else {
      return
    }
    let editorContexts = editorArea
      .children(where: { $0.identifier == "editor context" })
      .compactMap { el in el.firstParent(where: { $0.description == el.description }) }
    let editorsContainer = editorContexts.first?.firstParent(
      where: { $0.role == kAXSplitGroupRole })

    // Update editor inspectors.
    guard
      let editorInspectors = editorsContainer?.children.compactMap({ editorContainer in
        editorInspector(for: editorContainer)
      })
    else {
      return
    }
    let removedInspectors = editorInspectors.filter { inspector in
      !self.editorInspectors.contains(where: { $0 === inspector })
    }
    removedInspectors.forEach(stopTracking(_:))
    self.editorInspectors = editorInspectors

    // Update tabs
    let tabEls = editorsContainer?.children.flatMap { $0
      .firstChild(where: { $0.roleDescription == "tab group" })?
      .children(where: { $0.roleDescription == "tab" }) ?? []
    } ?? []
    // Use a set as there are several hierachies of tabs that can contain the same file.
    // Sort to avoid unnucessary state updates.
    let tabNames = Array(Set(tabEls.compactMap(\.title))).sorted()
    let existingTabs = internalState.value.tabs
    let focusedTabName = tabEls.first(where: { $0.doubleValue == 1 })?.title
    let documentURL = workspace.documentURL

    let focusEditorState = editorInspectors.lazy.compactMap { editor in
      let state = editor.state.currentValue
      return state.fileName == focusedTabName ? state : nil
    }.first

    let tabs = tabNames.map { tabName in
      let existingTab = existingTabs.first(where: { $0.fileName == tabName })
      if tabName == focusedTabName {
        return InternalXcodeWorkspaceState.Tab(
          fileName: tabName,
          knownPath: documentURL ?? existingTab?.knownPath,
          lastKnownContent: focusEditorState?.content ?? existingTab?.lastKnownContent)
      }
      return existingTab ?? .init(fileName: tabName, knownPath: nil, lastKnownContent: nil)
    }

    let focusedEditorId: String?? = editorInspectors.first(where: { $0.editorElement.isFocused })?.id ?? nil

    updateStateWith(
      tabs: tabs,
      editors: editorInspectors.map(\.state.currentValue).sorted(by: { $1.id == focusedEditorId }),
      documentURL: workspace.documentURL,
      focusedEditorId: focusedEditorId,
      focusedTabName: focusedTabName)
  }

  private let runningApplication: NSRunningApplication

  private let internalState: CurrentValueSubject<InternalXcodeWorkspaceState, Never>

  /// Returns the inspector for the corresponding editor.
  /// If the inspector is already created, it returns the existing inspector.
  /// If the inspector is not created, it creates a new inspector and subscribes to it.
  @MainActor
  private func editorInspector(for editorContainer: AXUIElement) -> SourceEditorObserver? {
    if
      let inspector = editorInspectors
        .filter(\.isElementValid)
        .first(where: { $0.element == editorContainer })
    {
      return inspector
    }
    guard
      let editorElement = editorContainer.firstChild(where: { $0.isSourceEditor }),
      let inspector = SourceEditorObserver(runningApplication: runningApplication, editorElement: editorElement)
    else {
      return nil
    }

    startTracking(inspector)
    return inspector
  }

  @MainActor
  private func startTracking(_ inspector: SourceEditorObserver) {
    let editors = internalState.value.editors
    updateStateWith(editors: editors + [inspector.state.currentValue])

    let cancellable = inspector
      .state
      .sink { [weak self] newValue in
        guard let self else { return }
        let editors = internalState.value.editors
        updateStateWith(editors: editors.map { oldValue in oldValue.id == newValue.id ? newValue : oldValue })
      }
    inspector.set(cleanupTask: cancellable)
    inspector.onElementInvalidated = { [weak self] inspector in
      self?.handleElementBecameInvalid(for: inspector)
    }
    editorInspectors.append(inspector)
  }

  private func stopTracking(_ inspector: SourceEditorObserver) {
    safelyMutate { state in
      state.editorInspectors = state.editorInspectors.filter { $0 !== inspector }
    }
  }

  private func updateStateWith(
    tabs: [InternalXcodeWorkspaceState.Tab]? = nil,
    editors: [InternalXcodeEditorState]? = nil,
    documentURL: URL?? = nil,
    focusedEditorId: String?? = nil,
    focusedTabName: String?? = nil)
  {
    let state = internalState.value
    // update the content with that of the editor when possible.
    let tabs = (tabs ?? state.tabs).map { tab -> InternalXcodeWorkspaceState.Tab in
      if let editor = editors?.first(where: { $0.fileName == tab.fileName }) {
        return InternalXcodeWorkspaceState.Tab(
          fileName: tab.fileName,
          knownPath: tab.knownPath,
          lastKnownContent: editor.content)
      } else {
        return tab
      }
    }
    let newState = InternalXcodeWorkspaceState(
      axElement: state.axElement,
      url: state.url,
      document: documentURL ?? state.document,
      tabs: tabs,
      editors: editors ?? state.editors,
      focusedTabName: focusedTabName ?? state.focusedTabName,
      focusedEditorId: focusedEditorId ?? state.focusedEditorId)
    if state != newState {
      internalState.send(newState)
    }
  }

  @MainActor
  private func handleElementBecameInvalid(for _: AXElementObserver) {
    refresh()
  }
}
