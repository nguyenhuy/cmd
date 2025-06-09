// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation
import SwiftUI

// MARK: - IconsLabelButton

public struct IconsLabelButton: View {

  public init(
    action: @escaping () -> Void,
    systemNames: [String],
    label: String,
    onHoverColor: Color = Color.primary.opacity(0.1),
    padding: CGFloat = 4,
    cornerRadius: CGFloat = 4)
  {
    self.action = action
    self.systemNames = systemNames
    self.label = label
    self.onHoverColor = onHoverColor
    self.padding = padding
    self.cornerRadius = cornerRadius
  }

  public var body: some View {
    HoveredButton(
      action: action,
      onHoverColor: onHoverColor,
      padding: padding,
      cornerRadius: cornerRadius)
    {
      HStack(spacing: 2) {
        Text(label)
        ForEach(Array(systemNames.enumerated()), id: \.offset) { _, systemName in
          Image(systemName: systemName)
        }
      }
    }
  }

  let action: () -> Void
  let systemNames: [String]
  let label: String
  let onHoverColor: Color
  let padding: CGFloat
  let cornerRadius: CGFloat
}

#if DEBUG
#Preview {
  VStack {
    IconsLabelButton(
      action: { },
      systemNames: ["command", "return"],
      label: "Accept")
    IconsLabelButton(
      action: { },
      systemNames: ["return"],
      label: "Send")
    IconsLabelButton(
      action: { },
      systemNames: ["shift", "command", "delete.left"],
      label: "Reject")
  }
}
#endif
