// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

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
