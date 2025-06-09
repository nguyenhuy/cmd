// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

// MARK: - IconButton

public struct IconButton: View {

  public init(
    action: @escaping () async -> Void,
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
    HoveredButton(
      action: {
        isRunning = true
        Task {
          await action()
          isRunning = false
          hasTapped = true
          Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            hasTapped = false
          }
        }
      },
      onHoverColor: onHoverColor,
      padding: padding,
      cornerRadius: cornerRadius)
    {
      Icon(systemName: iconSystemName)
    }
  }

  let systemName: String
  let onHoverColor: Color
  let padding: CGFloat
  let cornerRadius: CGFloat
  let withCheckMark: Bool

  @State private var isRunning = false
  @State private var hasTapped = false

  private let action: () async -> Void

  private var iconSystemName: String {
    if isRunning {
      return "progress.indicator"
    }
    if hasTapped, withCheckMark {
      return "checkmark"
    }
    return systemName
  }

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
