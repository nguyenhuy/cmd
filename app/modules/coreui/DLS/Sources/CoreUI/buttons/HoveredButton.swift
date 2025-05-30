// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - HoveredButton

public struct HoveredButton<Content: View>: View {

    /// Creates a button that changes its appearance when hovered.
    /// - Parameters:
    /// - action: The action to perform when the button is tapped.
    /// - onHoverColor: The color to apply when the button is hovered.
    /// - backgroundColor: The background color of the button.
    /// - padding: The amount of padding around the button content.
    /// - cornerRadius: The corner radius of the button.
    /// - content: A closure that returns the content of the button.
  public init(
    action: @escaping () -> Void,
    onHoverColor: Color = .clear,
    backgroundColor: Color = .clear,
    padding: CGFloat = 0,
    cornerRadius: CGFloat = 4,
    @ViewBuilder content: @escaping () -> Content)
  {
    self.action = action
    self.onHoverColor = onHoverColor
    self.backgroundColor = backgroundColor
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content
  }

  public var body: some View {
    Button(action: action, label: {
      content()
        .padding(padding)
        .tappableTransparentBackground()
        .background(isHovered ? onHoverColor : backgroundColor)
        .cornerRadius(cornerRadius)
    })
    .buttonStyle(.plain)
    .scaledToFit()
    .acceptClickThrough()
    .onHover(perform: { isHovered in
      self.isHovered = isHovered
    })
  }

  @State private var isHovered = false

  private let action: () -> Void
  private let onHoverColor: Color
  private let backgroundColor: Color
  private let padding: CGFloat
  private let cornerRadius: CGFloat
  private let content: () -> Content

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
