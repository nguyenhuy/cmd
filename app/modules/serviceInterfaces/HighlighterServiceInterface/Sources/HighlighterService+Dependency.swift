// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DependencyFoundation
import HighlightSwift

// MARK: - HighlighterServiceDependencyKey

public final class HighlighterServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue = Highlight()
  #else
  /// This is not read outside of DEBUG
  public static let testValue = Highlight()
  #endif
}

extension DependencyValues {
  public var highlighter: Highlight {
    get { self[HighlighterServiceDependencyKey.self] }
    set { self[HighlighterServiceDependencyKey.self] = newValue }
  }
}

extension BaseProviding {
  public var highlighter: Highlight {
    shared { Highlight() }
  }
}
