// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

/// From https://christiantietze.de/posts/2024/04/enable-swiftui-button-click-through-inactive-windows/
extension SwiftUI.View {
  /// Enable the view to receive "first mouse" events.
  ///
  /// "First mouse" is the click into an inactive window that brings it to
  /// the front (activates it) and potentially triggers whatever control was
  /// clicked on. Controls that do support this are "click-through", because
  /// you can click on the inactive window, "through" its activation
  /// process, into the control.
  ///
  /// ## Using Buttons
  ///
  /// Wrap a button like this to make it respond to first clicks. The first
  /// mouse acceptance of this wrapper makes the button perform its action:
  ///
  /// ```swift
  /// Button { ... } label: { ... }
  ///     .style(.plain) // Style breaks default click-through
  ///     .acceptClickThrough() // Enables click-through again
  /// ```
  ///
  /// > Note: You need to stay somewhat close to the button. You can use
  ///         an `HStack`/`VStack` that wrap buttons, but not on a stack
  ///         that wraps custom views that contain the button 2+ levels deep.
  ///
  /// ## Using other tap gesture-enabled controls
  ///
  /// This also propagates "first mouse" tap gestures to interactive
  /// controls that are not buttons:
  ///
  /// ```swift
  /// VStack {
  ///     ForEach(...) { item in
  ///          CustomViewWithoutButtons(item)
  ///             .acceptClickThrough()
  ///             .onTapGesture { ... }
  ///     }
  /// }
  /// ```
  @ViewBuilder
  public func acceptClickThrough(disabled: Bool = false) -> some View {
    if disabled {
      self
    } else {
      ClickThroughBackdrop(self)
    }
  }
}

// MARK: - ClickThroughBackdrop

private struct ClickThroughBackdrop<Content: SwiftUI.View>: NSViewRepresentable {

  init(_ content: Content) {
    self.content = content
  }

  final class Backdrop: NSHostingView<Content> {
    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
      true
    }
  }

  let content: Content

  func makeNSView(context _: Context) -> Backdrop {
    let backdrop = Backdrop(rootView: content)
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    return backdrop
  }

  func updateNSView(_ nsView: Backdrop, context _: Context) {
    nsView.rootView = content
  }
}
