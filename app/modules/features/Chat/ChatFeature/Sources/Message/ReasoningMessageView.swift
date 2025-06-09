// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import DLS
import SwiftUI

struct ReasoningMessageView: View {
  let reasoning: ChatMessageReasoningContent

  var body: some View {
    VStack(alignment: .leading) {
      Button(action: {
        isExpanded.toggle()
      }) {
        HStack(spacing: 0) {
          Icon(systemName: iconName(isHovered: isHovered))
            .frame(square: iconSize(isHovered: isHovered))
            .padding(.trailing, 8)
            .frame(width: 24)
          Text(thinkingDescription)
          if reasoning.isStreaming {
            ThreeDotsLoadingAnimation()
          }
        }
        .onHover { isHovered in
          self.isHovered = isHovered
        }
        .foregroundColor(isHovered ? colorScheme.primaryForeground : colorScheme.secondaryForeground)
        .tappableTransparentBackground()
      }
      .buttonStyle(.plain)
      if isExpanded {
        Text(reasoning.text)
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(.secondary)
          .padding(.leading)
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  @State private var isExpanded = false

  @State private var isHovered = false

  private var thinkingDescription: String {
    if reasoning.isStreaming {
      return "Thinking"
    }
    if let reasoningDuration = reasoning.reasoningDuration {
      return "Thought for \(formatDuration(reasoningDuration))"
    } else {
      return "Thought for a bit"
    }
  }

  private func iconName(isHovered: Bool) -> String {
    if reasoning.isStreaming {
      return "brain"
    }
    if isExpanded {
      return "chevron.down"
    }
    if isHovered {
      return "chevron.right"
    }
    return "brain"
  }

  private func iconSize(isHovered: Bool) -> CGFloat {
    iconName(isHovered: isHovered) == "brain" ? 16 : 8
  }

  private func formatDuration(_ duration: Double) -> String {
    let seconds = Int(duration)

    if seconds < 60 {
      return "\(seconds)s"
    } else if seconds < 3600 {
      let minutes = seconds / 60
      return "\(minutes)mn"
    } else {
      let hours = seconds / 3600
      return "\(hours)h"
    }
  }

}
