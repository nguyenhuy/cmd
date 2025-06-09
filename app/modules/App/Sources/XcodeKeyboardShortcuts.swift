// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppEventServiceInterface
import ChatAppEvents
@preconcurrency import Combine
import Dependencies
import KeyboardShortcuts
import ThreadSafe
import XcodeObserverServiceInterface

// MARK: - XcodeKeyboardShortcutsManager

// TODO: Remove @unchecked when https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed
@ThreadSafe
final class XcodeKeyboardShortcutsManager: @unchecked Sendable {

  init(appsActivationState: AnyPublisher<AppsActivationState, Never>) {
    registerActions()

    observeXcodeState(appsActivationState: appsActivationState)
    enable([.hideChat])
  }

  private var cancellables: Set<AnyCancellable> = []

  private var enabledShortcutNames = Set<String>()

  @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry

  /// This can be moved to the initializer once https://github.com/swiftlang/swift/issues/80050 is fixed.
  private func observeXcodeState(appsActivationState: AnyPublisher<AppsActivationState, Never>) {
    let cancellable = appsActivationState
      .sink { @Sendable [weak self] appsActivationState in
        guard let self else { return }
        // Handle de-activations first, then activations.
        if !appsActivationState.isHostAppActive {
          disable(KeyboardShortcuts.Name.hostAppShortcuts)
        }
        if !appsActivationState.isXcodeActive {
          disable(KeyboardShortcuts.Name.xcodeShortcuts)
        }
        if appsActivationState.isHostAppActive {
          enable(KeyboardShortcuts.Name.hostAppShortcuts)
        }
        if appsActivationState.isXcodeActive {
          enable(KeyboardShortcuts.Name.xcodeShortcuts)
        }
      }
    inLock { $0.cancellables.insert(cancellable) }
  }

  /// Manually tracks enabled shortcuts due to https://github.com/sindresorhus/KeyboardShortcuts/issues/217
  private func enable(_ shortcuts: [KeyboardShortcuts.Name]) {
    KeyboardShortcuts.enable(shortcuts)
    inLock { state in
      for shortcut in shortcuts { state.enabledShortcutNames.insert(shortcut.rawValue) }
    }
  }

  private func disable(_ shortcuts: [KeyboardShortcuts.Name]) {
    KeyboardShortcuts.disable(shortcuts)
    inLock { state in
      for shortcut in shortcuts { state.enabledShortcutNames.remove(shortcut.rawValue) }
    }
  }

  private func registerActions() {
    on(.ask, trigger: AddCodeToChatEvent(newThread: false, chatMode: .ask))
    on(.askInNewThread, trigger: AddCodeToChatEvent(newThread: true, chatMode: .ask))
    on(.agent, trigger: AddCodeToChatEvent(newThread: false, chatMode: .agent))
    on(.agentInNewThread, trigger: AddCodeToChatEvent(newThread: true, chatMode: .agent))
    on(.edit, trigger: EditEvent())
    on(.generate, trigger: GenerateEvent())
    on(.hideChat, trigger: HideChatEvent())
    on(.new, trigger: NewChatEvent())
    on(.switchToAskMode, trigger: ChangeChatModeEvent(chatMode: .ask))
    on(.switchToAgentMode, trigger: ChangeChatModeEvent(chatMode: .agent))
  }

  private func on(_ keyEvent: KeyboardShortcuts.Name, trigger event: AppEvent) {
    KeyboardShortcuts.onKeyUp(for: keyEvent) {
      Task { [weak self] in
        guard let self else { return }
        if enabledShortcutNames.contains(keyEvent.rawValue) {
          _ = await appEventHandlerRegistry.handle(event: event)
        }
      }
    }
  }
}

extension KeyboardShortcuts.Name {
  static let hideChat = Self("hideChat", default: .init(.escape, modifiers: [.command]))
  // Xcode shortcuts
  static let ask = Self("ask", default: .init(.l, modifiers: [.command]))
  static let askInNewThread = Self("askInNewThread", default: .init(.l, modifiers: [.command, .shift]))
  static let agent = Self("agent", default: .init(.i, modifiers: [.command]))
  static let agentInNewThread = Self("agentInNewThread", default: .init(.i, modifiers: [.command, .shift]))
  static let edit = Self("edit", default: .init(.k, modifiers: [.command, .shift]))
  static let generate = Self("generate", default: .init(.k, modifiers: [.command]))

  static let xcodeShortcuts = [
    Self.ask,
    Self.askInNewThread,
    Self.agent,
    Self.agentInNewThread,
    Self.edit,
    Self.generate,
  ]
  // Host app shortcuts
  static let new = Self("new", default: .init(.n, modifiers: [.command]))
  static let switchToAskMode = Self("switchToAskMode", default: .init(.l, modifiers: [.command]))
  static let switchToAgentMode = Self("switchToAgentMode", default: .init(.i, modifiers: [.command]))

  static let hostAppShortcuts = [
    Self.new,
    Self.switchToAskMode,
    Self.switchToAgentMode,
  ]
}
