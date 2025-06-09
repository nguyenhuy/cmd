// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import ConcurrencyFoundation
import SwiftUI

/// A View that shares the hovered position to its content.
/// This can be useful when having one of the contained element needing the hovered information while letting other elements receive hit testing.
public struct HoverReader<Content: View>: View {

  public init(
    @ViewBuilder content: @escaping (ObservableValue<CGPoint?>) -> Content)
  {
    self.content = content
  }

  public var body: some View {
    content(hoverLocation)
      .onContinuousHover(coordinateSpace: .global) { phase in
        switch phase {
        case .active(let point): hoverLocation.value = point
        case .ended: hoverLocation.value = nil
        }
      }
  }

  private let hoverLocation = ObservableValue<CGPoint?>(nil)

  private let content: (ObservableValue<CGPoint?>) -> Content
}
