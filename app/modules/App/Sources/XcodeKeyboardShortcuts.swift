// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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

  init(xcodeObserver: XcodeObserver) {
    registerActions()

    observeXcodeState(xcodeObserver: xcodeObserver)
  }

  func enable() {
    KeyboardShortcuts.enable([.chat, .addToChat, .edit, .generate])
  }

  func disable() {
    KeyboardShortcuts.disable([.chat, .addToChat, .edit, .generate])
  }

  private var cancellables: Set<AnyCancellable> = []

  @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry

  /// This can be moved to the initializer once https://github.com/swiftlang/swift/issues/80050 is fixed.
  private func observeXcodeState(xcodeObserver: XcodeObserver) {
    let cancellable = xcodeObserver.statePublisher
      .map { $0.activeInstance?.isActive }
      .removeDuplicates()
      .sink { @Sendable [weak self] isXcodeActive in
        if isXcodeActive == true {
          self?.enable()
        } else {
          self?.disable()
        }
      }
    safelyMutate { $0.cancellables.insert(cancellable) }
  }

  private func registerActions() {
    KeyboardShortcuts.onKeyUp(for: .chat) {
      Task { [weak self] in
        await self?.appEventHandlerRegistry.handle(event: AddCodeToChatEvent())
      }
    }
    KeyboardShortcuts.onKeyUp(for: .addToChat) {
      Task { [weak self] in
        await self?.appEventHandlerRegistry.handle(event: AddCodeToChatEvent())
      }
    }
    KeyboardShortcuts.onKeyUp(for: .edit) {
      Task { [weak self] in
        await self?.appEventHandlerRegistry.handle(event: EditEvent())
      }
    }
    KeyboardShortcuts.onKeyUp(for: .generate) {
      Task { [weak self] in
        await self?.appEventHandlerRegistry.handle(event: GenerateEvent())
      }
    }
    KeyboardShortcuts.onKeyUp(for: .hideChat) {
      Task { [weak self] in
        await self?.appEventHandlerRegistry.handle(event: HideChatEvent())
      }
    }
  }
}

extension KeyboardShortcuts.Name {
  static let chat = Self("chat", default: .init(.l, modifiers: [.command]))
  // TODO: remove
  static let addToChat = Self("addToChat", default: .init(.l, modifiers: [.command, .shift]))
  static let edit = Self("edit", default: .init(.k, modifiers: [.command, .shift]))
  static let hideChat = Self("hideChat", default: .init(.escape, modifiers: [.command]))
  static let generate = Self("generate", default: .init(.k, modifiers: [.command]))
}
