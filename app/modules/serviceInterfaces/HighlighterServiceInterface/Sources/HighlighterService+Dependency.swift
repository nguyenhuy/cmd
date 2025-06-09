// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
