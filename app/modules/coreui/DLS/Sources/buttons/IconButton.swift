// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - IconButton

public struct IconButton: View {

  public init(
    action: @escaping () -> Void,
    systemName: String,
    onHoverColor: Color = .clear,
    padding: CGFloat = 0,
    cornerRadius: CGFloat = 4,
    withCheckMark: Bool = false)
  {
    self.action = action
    self.systemName = systemName
    self.onHoverColor = onHoverColor
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.withCheckMark = withCheckMark
  }

  public var body: some View {
    Button(action: {
      action()
      hasTapped = true
      Task {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        hasTapped = false
      }
    }, label: {
      Icon(systemName: hasTapped && withCheckMark ? "checkmark" : systemName)
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
  let systemName: String
  let onHoverColor: Color
  let padding: CGFloat
  let cornerRadius: CGFloat
  let withCheckMark: Bool

  @State private var hasTapped = false
  @State private var isHovered = false
}

#if DEBUG
#Preview {
  VStack {
    IconButton(action: { }, systemName: "doc.on.doc", withCheckMark: true)
      .frame(width: 10, height: 10)
      .border(.blue)
    IconButton(action: { }, systemName: "doc.on.doc", withCheckMark: true)
      .frame(width: 20, height: 20)
      .border(.blue)
    IconButton(action: { }, systemName: "doc.on.doc", withCheckMark: true)
      .frame(width: 10, height: 20)
      .border(.blue)

    IconButton(action: { }, systemName: "doc.on.doc", onHoverColor: .red, padding: 5)
      .frame(width: 20, height: 20)
      .border(.blue)
  }
  .padding()
}

#endif
