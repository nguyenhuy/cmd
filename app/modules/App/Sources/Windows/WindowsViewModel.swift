// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventServiceInterface
import AppKit
import ChatAppEvents
import Combine
import Dependencies
import Observation
import PermissionsServiceInterface
import XcodeObserverServiceInterface

// MARK: - WindowsViewModel

@Observable @MainActor
final class WindowsViewModel {

  init() {
    state = .init(isSidePanelVisible: false, isSetupVisible: false)

    Task {
      await appEventHandlerRegistry.registerHandler { [weak self] event in
        await self?.handle(appEvent: event) ?? false
      }
    }
    permissionsService.status(for: .accessibility).sink { [weak self] isGranted in
      self?.handle(.accessibilityPermissionChanged(isGranted: isGranted))
    }.store(in: &cancellables)
  }

  struct State {
    let isSidePanelVisible: Bool
    let isSetupVisible: Bool

    func with(
      isSidePanelVisible: Bool? = nil,
      isSetupVisible: Bool? = nil)
      -> State
    {
      State(
        isSidePanelVisible: isSidePanelVisible ?? self.isSidePanelVisible,
        isSetupVisible: isSetupVisible ?? self.isSetupVisible)
    }
  }

  enum WindowsAction {
    case showApplication
    case closeSidePanel
    case stopChat
    case accessibilityPermissionChanged(isGranted: Bool?)
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
    case .accessibilityPermissionChanged(let isGranted):
      if isGranted == true {
        state = state.with(isSetupVisible: false)
      } else if isGranted == false {
        state = state.with(isSetupVisible: true)
      }
    }
  }

  @ObservationIgnored
  @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry
  @ObservationIgnored
  @Dependency(\.permissionsService) private var permissionsService

  private var cancellables = Set<AnyCancellable>()

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
