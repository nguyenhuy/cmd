// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Dependencies
import Foundation
@_exported import HighlightSwift

// MARK: - HighlighterServiceProviding

public protocol HighlighterServiceProviding {
  var highlighter: Highlight { get }
}

extension HighlightColors {
  public static var codeHighlight: HighlightColors {
    let isDarkMode = NSAppearance.currentDrawing().bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    if isDarkMode {
      return .dark(.xcode)
    } else {
      return .light(.xcode)
    }
  }
}
