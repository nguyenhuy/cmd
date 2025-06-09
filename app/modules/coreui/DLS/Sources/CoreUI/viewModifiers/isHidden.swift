// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

// MARK: - IsHidden

struct IsHidden: ViewModifier {
  var hidden = false
  var remove = false
  func body(content: Content) -> some View {
    if hidden {
      if remove {
      } else {
        content.hidden()
      }
    } else {
      content
    }
  }
}

extension View {
  /// Conditionally hide or remove the view
  public func isHidden(_ hidden: Bool = false, remove: Bool = false) -> some View {
    modifier(
      IsHidden(
        hidden: hidden,
        remove: remove))
  }
}
