// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SwiftUI

private let iconSize: CGFloat = 11

// MARK: - AgentModeView

struct AgentModeView: View {
  var body: some View {
    HStack(spacing: 3) {
      Icon(systemName: "infinity")
        .frame(width: iconSize, height: iconSize)
      Text("Agent")
      Text("⌘I")
    }
  }
}

// MARK: - AskModeView

struct AskModeView: View {
  var body: some View {
    HStack(spacing: 3) {
      Icon(systemName: "bubble")
        .frame(width: iconSize, height: iconSize)
      Text("Ask")
      Text("⌘L")
    }
  }
}
