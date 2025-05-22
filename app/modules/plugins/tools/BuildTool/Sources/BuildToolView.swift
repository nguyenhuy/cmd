// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CodePreview
import DLS
import ServerServiceInterface
import SwiftUI
import ToolFoundation

// MARK: - BuildTool.Use + DisplayableToolUse

extension BuildTool.Use: DisplayableToolUse {
  public var body: AnyView {
    AnyView(ToolUseView(toolUse: ToolUseViewModel(
      buildType: input.for,
      status: status)))
  }
}

// MARK: - ToolUseView

struct ToolUseView: View {

  @Bindable var toolUse: ToolUseViewModel

  var body: some View {
    switch toolUse.status {
    case .running:
      content(statusDescription: "Building...")
    case .completed(.success):
      content(statusDescription: "Build for succeeded")
    case .completed(.failure(let error)):
      content(statusDescription: "Build for \(toolUse.buildType) failed: \(error.localizedDescription)")
    default:
      VStack { }
    }
  }

  @State private var isExpanded = false
  @State private var isHovered = false

  @Environment(\.colorScheme) private var colorScheme

  private var foregroundColor: Color {
    if isHovered {
      .primary
    } else {
      colorScheme.toolUseForeground
    }
  }

  @ViewBuilder
  private func content(statusDescription: String) -> some View {
    VStack(alignment: .leading) {
      HStack {
        if isExpanded {
          Icon(systemName: "chevron.down")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        } else if isHovered {
          Icon(systemName: "chevron.right")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        } else {
          Icon(systemName: "hammer")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        }
        Text(statusDescription)
          .font(.system(.body, design: .monospaced))
          .foregroundColor(foregroundColor)
          .lineLimit(1)
        Spacer(minLength: 0)
          .frame(width: 15)
      }
      .tappableTransparentBackground()
      .onTapGesture { isExpanded.toggle() }
      .acceptClickThrough()
      if isExpanded {
        VStack(alignment: .leading, spacing: 8) {
          Text("Build type: \(toolUse.buildType)")
            .font(.system(.body, design: .monospaced))
            .foregroundColor(foregroundColor)
        }
        .frame(maxWidth: 600, alignment: .leading)
      }
    }.onHover { isHovered = $0 }
  }
}
