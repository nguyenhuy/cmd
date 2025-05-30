// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftUI

// MARK: - IconsLabelButton

public struct IconsLabelButton: View {
  
  public init(
    action: @escaping () -> Void,
    systemNames: [String],
    label: String)
  {
    self.action = action
    self.systemNames = systemNames
    self.label = label
  }
  
  public var body: some View {
    Button(action: action) {
      HStack(spacing: 2) {
        Text(label)
        ForEach(Array(systemNames.enumerated()), id: \.offset) { _, systemName in
          Image(systemName: systemName)
        }
      }
    }
    .acceptClickThrough()
    .buttonStyle(.plain)
  }
  
  let action: () -> Void
  let systemNames: [String]
  let label: String
}

#Preview {
  VStack {
    IconsLabelButton(
      action: {},
      systemNames: ["command", "return"],
      label: "Accept")
    IconsLabelButton(
      action: {},
      systemNames: ["return"],
      label: "Send")
    IconsLabelButton(
      action: {},
      systemNames: ["shift", "command", "delete.left"],
      label: "Reject")
  }
}
