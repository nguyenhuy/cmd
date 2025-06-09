// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppEventServiceInterface
import DependencyFoundation
import LoggingServiceInterface
import ThreadSafe

// MARK: - DefaultAppEventHandlerRegistry

@ThreadSafe
final class DefaultAppEventHandlerRegistry: AppEventHandlerRegistry {

  init() { }

  /// Registers a handler for app events.
  /// This handler will be called for every app event that has not been handled by a handler previously registered.
  func registerHandler(_ handler: @escaping @Sendable (_ appEvent: AppEvent) async -> Bool) {
    eventHandlers.append(handler)
  }

  /// Broadcasts an app event to all registered handlers.
  /// Returns true if the event was handled by one handler.
  func handle(event: AppEvent) async -> Bool {
    defaultLogger.log("Broadcasting event \(event)")
    for handler in eventHandlers {
      if await handler(event) {
        return true
      }
    }
    return false
  }

  private var eventHandlers: [@Sendable (_ appEvent: AppEvent) async -> Bool] = []
}

extension BaseProviding {
  public var appEventHandlerRegistry: AppEventHandlerRegistry {
    shared {
      DefaultAppEventHandlerRegistry()
    }
  }
}
