// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import ServerServiceInterface
import SwiftUI
import ToolFoundation

// MARK: - AskFollowUpTool.Use + DisplayableToolUse

extension AskFollowUpTool.Use: DisplayableToolUse {
  public var body: AnyView {
    AnyView(ToolUseView(toolUse: ToolUseViewModel(
      status: status,
      input: input,
      selectFollowUp: select(followUp:))))
  }
}

// MARK: - ToolUseView

struct ToolUseView: View {

  @Bindable var toolUse: ToolUseViewModel

  var body: some View {
    switch toolUse.status {
    case .running:
      followUpView(selection: nil)
    case .completed(.success(let output)):
      followUpView(selection: output.response)
    default:
      VStack { }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  @ViewBuilder
  private func followUpView(selection: String?) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(toolUse.input.question)
        .padding(.bottom, 8)
      ForEach(toolUse.input.followUp, id: \.self) { choice in
        Button(action: { toolUse.selectFollowUp(choice) }) {
          Text(choice)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .roundedCornerWithBorder(borderColor: foregroundColor(for: choice, with: selection), radius: 3)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(selection == nil)
        .foregroundColor(foregroundColor(for: choice, with: selection))
        .padding(.vertical, 4)
      }
    }
    .padding(.vertical, 8)
  }

  private func foregroundColor(for choice: String, with selection: String?) -> Color {
    guard let selection else { return .primary }
    return selection == choice ? .primary : .secondary
  }
}
