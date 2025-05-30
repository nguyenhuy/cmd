// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
import AppKit
import Foundation
import XcodeObserverServiceInterface

extension MockXcodeObserver {
  convenience init(workspaceURL: URL) {
    let mockElement = AnyAXUIElement(
      isOnScreen: { true },
      raise: { },
      appKitFrame: { .zero },
      cgFrame: { .zero },
      pid: { 0 },
      setAppKitframe: { _ in },
      id: "1")
    self.init(.state(
      XcodeState(
        activeApplicationProcessIdentifier: 1,
        previousApplicationProcessIdentifier: nil,
        xcodesState: [
          XcodeAppState(processIdentifier: 1, isActive: true, workspaces: [
            XcodeWorkspaceState(
              axElement: mockElement,
              url: workspaceURL,
              editors: [],
              isFocused: true,
              document: nil,
              tabs: []),
          ]),
        ])))
  }
}
