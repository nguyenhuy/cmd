// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Foundation

typealias WindowInfo = [CFString: AnyObject]

extension WindowInfo {
  var windowNumber: CGWindowID? {
    self[kCGWindowNumber] as? CGWindowID
  }

  var isOnScreen: Bool {
    self[kCGWindowIsOnscreen] as? Bool ?? false
  }

  static func window(withNumber windowNumber: CGWindowID) -> WindowInfo? {
    (CGWindowListCopyWindowInfo(.optionIncludingWindow, windowNumber) as? [WindowInfo])?.first
  }

  static func findWindowsMatching(pid: pid_t?, cgFrame: CGRect?) -> [WindowInfo] {
    guard let pid else { return [] }

    guard
      let cgFrame,
      let windows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [WindowInfo]
    else {
      return []
    }
    return windows.compactMap { window in
      if window[kCGWindowOwnerPID] as? Int32 != pid {
        return nil
      }

      var bounds = CGRect.zero
      guard
        let windowBounds = window[kCGWindowBounds], CGRectMakeWithDictionaryRepresentation(
          windowBounds as! CFDictionary,
          &bounds)
      else {
        return nil
      }
      return bounds == cgFrame ? window : nil
    }
  }
}
