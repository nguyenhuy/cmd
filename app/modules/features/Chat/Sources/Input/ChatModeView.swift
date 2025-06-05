// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFoundation
import DLS
import SwiftUI

private let iconSize: CGFloat = 11

// MARK: - AgentModeView

struct AgentModeView: View {
  var body: some View {
    HStack(spacing: 3) {
      Icon(systemName: ChatMode.agent.systemImageName)
        .frame(width: iconSize, height: iconSize)
      Text(ChatMode.agent.name)
      Text(ChatMode.agent.commandDisplay)
    }
  }
}

// MARK: - AskModeView

struct AskModeView: View {
  var body: some View {
    HStack(spacing: 3) {
      Icon(systemName: ChatMode.ask.systemImageName)
        .frame(width: iconSize, height: iconSize)
      Text(ChatMode.ask.name)
      Text(ChatMode.ask.commandDisplay)
    }
  }
}
