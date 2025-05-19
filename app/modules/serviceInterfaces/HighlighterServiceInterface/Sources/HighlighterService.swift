// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import Foundation
@_exported import HighlightSwift

// MARK: - HighlighterServiceProviding

public protocol HighlighterServiceProviding {
  var highlighter: Highlight { get }
}
