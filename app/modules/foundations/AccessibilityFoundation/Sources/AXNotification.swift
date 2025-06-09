// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppKit

// MARK: - AXNotification

/// A typed representation of some of the notifications that can be sent by the accessibility API.
public enum AXNotification {
  case titleChanged
  case applicationActivated
  case applicationDeactivated
  case moved
  case resized
  case mainWindowChanged
  case focusedWindowChanged
  case focusedUIElementChanged
  case windowMoved
  case windowResized
  case windowMiniaturized
  case windowDeminiaturized
  case created
  case uiElementDestroyed
  case xcodeCompletionPanelChanged
  case valueChanged
  case selectedTextChanged
  case applicationTerminated
}

extension AXNotification {

  public init?(rawValue: String) {
    switch rawValue {
    case kAXTitleChangedNotification:
      self = .titleChanged
    case kAXApplicationActivatedNotification:
      self = .applicationActivated
    case kAXApplicationDeactivatedNotification:
      self = .applicationDeactivated
    case kAXMovedNotification:
      self = .moved
    case kAXResizedNotification:
      self = .resized
    case kAXMainWindowChangedNotification:
      self = .mainWindowChanged
    case kAXFocusedWindowChangedNotification:
      self = .focusedWindowChanged
    case kAXFocusedUIElementChangedNotification:
      self = .focusedUIElementChanged
    case kAXWindowMovedNotification:
      self = .windowMoved
    case kAXWindowResizedNotification:
      self = .windowResized
    case kAXWindowMiniaturizedNotification:
      self = .windowMiniaturized
    case kAXWindowDeminiaturizedNotification:
      self = .windowDeminiaturized
    case kAXCreatedNotification:
      self = .created
    case kAXUIElementDestroyedNotification:
      self = .uiElementDestroyed
    case kAXValueChangedNotification:
      self = .valueChanged
    case kAXSelectedTextChangedNotification:
      self = .selectedTextChanged
    default:
      return nil
    }
  }
}
