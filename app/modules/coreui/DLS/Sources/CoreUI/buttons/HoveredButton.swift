// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - HoveredButton

public struct HoveredButton<Content: View>: View {

  public init(
    action: @escaping () -> Void,
    onHoverColor: Color = .clear,
    padding: CGFloat = 0,
    cornerRadius: CGFloat = 4,
    @ViewBuilder content: @escaping () -> Content)
  {
    self.action = action
    self.onHoverColor = onHoverColor
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content
  }

  public var body: some View {
    Button(action: action, label: {
      content()
        .padding(padding)
        .tappableTransparentBackground()
        .background(isHovered ? onHoverColor : .clear)
        .cornerRadius(cornerRadius)
    })
    .buttonStyle(.plain)
    .scaledToFit()
    .onHover(perform: { isHovered in
      self.isHovered = isHovered
    })
    .acceptClickThrough()
  }

  let action: () -> Void
  let onHoverColor: Color
  let padding: CGFloat
  let cornerRadius: CGFloat
  let content: () -> Content

  @State private var isHovered = false
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
