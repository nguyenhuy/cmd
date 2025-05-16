// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventServiceInterface
import AppKit
import ChatAppEvents
import Dependencies
import Observation
import XcodeObserverServiceInterface

// MARK: - WindowsViewModel

@Observable @MainActor
final class WindowsViewModel {

  init() {
    state = .init(isSidePanelVisible: false)

    Task {
      await appEventHandlerRegistry.registerHandler { [weak self] event in
        await self?.handle(appEvent: event) ?? false
      }
    }
  }

  struct State {
    let isSidePanelVisible: Bool

    func with(isSidePanelVisible: Bool?) -> State {
      State(
        isSidePanelVisible: isSidePanelVisible ?? self.isSidePanelVisible)
    }
  }

  enum WindowsAction {
    case showApplication
    case closeSidePanel
    case stopChat
  }

  private(set) var state: State

  func handle(_ action: WindowsAction) {
    switch action {
    case .showApplication:
      state = state.with(isSidePanelVisible: true)
    case .closeSidePanel:
      state = state.with(isSidePanelVisible: false)
    case .stopChat:
      state = state.with(isSidePanelVisible: false)
    }
  }

  @ObservationIgnored
  @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry

  private func handle(appEvent: AppEvent) -> Bool {
    if appEvent is AddCodeToChatEvent {
      handle(.showApplication)
      // Return false here to allow for other consumers to react to the event,
      // for instance to add code to the chat
      return false
    } else if appEvent is HideChatEvent {
      handle(.stopChat)
      // TODO: reset Xcode position
    }
    return false
  }

}
