// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
import Combine
import ConcurrencyFoundation
import Foundation

// MARK: - XcodeObserver

public protocol XcodeObserver: Sendable {
  var statePublisher: ReadonlyCurrentValueSubject<AXState<XcodeState>, Never> { get }
  var axNotifications: AnyPublisher<AXNotification, Never> { get }
}

extension XcodeObserver {
  public var state: AXState<XcodeState> {
    statePublisher.currentValue
  }
}

extension AXState<XcodeState> {

  /// The instance of Xcode that is currently active (Xcode will be inactive if the host app is active and this would then be `nil`).
  public var activeInstance: XcodeAppState? {
    wrapped?.xcodesState
      .first(where: { $0.isActive })
  }

  /// The instance of Xcode that is either active or was last used.
  public var focusedInstance: XcodeAppState? {
    wrapped?.xcodesState
      .first
  }

  public var focusedWorkspace: XcodeWorkspaceState? {
    focusedInstance?.workspaces
      .first(where: { $0.isFocused })
  }

  public var focusedTabURL: URL? {
    focusedWorkspace?.tabs
      .first(where: { $0.isFocused })?.knownPath
  }
}

// MARK: - XcodeObserverProviding

public protocol XcodeObserverProviding {
  var xcodeObserver: XcodeObserver { get }
}

// MARK: - IsHostAppActiveProviding

public protocol IsHostAppActiveProviding {
  var isHostAppActive: AnyPublisher<Bool, Never> { get }
}
