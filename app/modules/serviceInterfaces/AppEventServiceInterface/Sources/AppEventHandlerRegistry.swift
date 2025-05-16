// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

// MARK: - AppEvent

/// An app wide event.
public protocol AppEvent: Sendable { }

// MARK: - AppEventHandler

/// A handler for app wide events.
public protocol AppEventHandler {
  func handle(appEvent: AppEvent) async -> Bool
}

// MARK: - AppEventHandlerRegistry

/// A registry for app event handlers.
public protocol AppEventHandlerRegistry: Sendable {
  /// Registers a handler for app events.
  /// - Parameter handler: The handler to register. It will be called when any app event is triggered. Returns whether the event was handled.
  func registerHandler(_ handler: @escaping @Sendable (_ appEvent: AppEvent) async -> Bool) async
  /// Send an event to the registry that will dispatch it to the right handler.
  func handle(event: AppEvent) async -> Bool
}

// MARK: - AppEventHandlerRegistryProviding

public protocol AppEventHandlerRegistryProviding {
  var appEventHandlerRegistry: AppEventHandlerRegistry { get }
}
