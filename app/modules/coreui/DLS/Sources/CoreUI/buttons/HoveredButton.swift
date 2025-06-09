// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - HoveredButton

public struct HoveredButton<Content: View>: View {

  /// Creates a button that changes its appearance when hovered.
  /// - Parameters:
  ///   - action: The action to perform when the button is tapped.
  ///   - onHoverColor: The color to apply when the button is hovered.
  ///   - backgroundColor: The background color of the button.
  ///   - padding: The amount of padding around the button content.
  ///   - cornerRadius: The corner radius of the button.
  ///   - isEnable: Whether the button is enabled and interactive.
  ///   - disableClickThrough: Whether to disable click-through behavior.
  ///   Because it uses an NSHosting view, this might cause issues in some cases with dynamic content size.
  ///   - content: A closure that returns the content of the button.
  public init(
    action: @escaping () -> Void,
    onHoverColor: Color = .clear,
    backgroundColor: Color = .clear,
    padding: CGFloat = 0,
    cornerRadius: CGFloat = 4,
    isEnable: Bool = true,
    disableClickThrough: Bool = false,
    @ViewBuilder content: @escaping () -> Content)
  {
    self.action = action
    self.onHoverColor = onHoverColor
    self.backgroundColor = backgroundColor
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.isEnable = isEnable
    self.disableClickThrough = disableClickThrough
    self.content = { _ in content() }
  }

  /// Creates a button that changes its appearance when hovered.
  /// - Parameters:
  ///   - action: The action to perform when the button is tapped.
  ///   - onHoverColor: The color to apply when the button is hovered.
  ///   - backgroundColor: The background color of the button.
  ///   - padding: The amount of padding around the button content.
  ///   - cornerRadius: The corner radius of the button.
  ///   - isEnable: Whether the button is enabled and interactive.
  ///   - disableClickThrough: Whether to disable click-through behavior.
  ///   Because it uses an NSHosting view, this might cause issues in some cases with dynamic content size.
  ///   - content: A closure that returns the content of the button, receiving hover state as parameter.
  public init(
    action: @escaping () -> Void,
    onHoverColor: Color = .clear,
    backgroundColor: Color = .clear,
    padding: CGFloat = 0,
    cornerRadius: CGFloat = 4,
    isEnable: Bool = true,
    disableClickThrough: Bool = false,
    @ViewBuilder content: @escaping (Bool) -> Content)
  {
    self.action = action
    self.onHoverColor = onHoverColor
    self.backgroundColor = backgroundColor
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content
    self.isEnable = isEnable
    self.disableClickThrough = disableClickThrough
  }

  public var body: some View {
    Button(action: action, label: {
      content(isHovered)
        .padding(padding)
        .tappableTransparentBackground()
        .background((isHovered && isEnable) ? onHoverColor : backgroundColor)
        .cornerRadius(cornerRadius)
    })
    .buttonStyle(.plain)
    .acceptClickThrough(disabled: disableClickThrough)
    .onHover(perform: { isHovered in
      self.isHovered = isHovered
    })
    .allowsHitTesting(isEnable)
  }

  @State private var isHovered = false

  private let action: () -> Void
  private let onHoverColor: Color
  private let backgroundColor: Color
  private let padding: CGFloat
  private let cornerRadius: CGFloat
  private let content: (Bool) -> Content
  private let isEnable: Bool
  private let disableClickThrough: Bool

}

#if DEBUG
#Preview {
  VStack {
    HoveredButton(action: { }, onHoverColor: .red, padding: 5) {
      Text("Custom Button")
    }
    .frame(width: 100, height: 30)
    .border(.blue)

    HoveredButton(action: { }) {
      HStack {
        Image(systemName: "star")
        Text("Star")
      }
    }
    .frame(width: 80, height: 25)
    .border(.green)
  }
  .padding()
}
#endif
