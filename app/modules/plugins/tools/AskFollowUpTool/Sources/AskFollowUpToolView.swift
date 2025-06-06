// Copyright command. All rights reserved.
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
    VStack(alignment: .leading, spacing: 8) {
      Text(toolUse.input.question)
        .textSelection(.enabled)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: false)
        .padding(.bottom, 8)
      ForEach(toolUse.input.followUp, id: \.self) { choice in
        HoveredButton(
          action: { toolUse.selectFollowUp(choice) },
          onHoverColor: colorScheme.tertiarySystemBackground,
          backgroundColor: selection == choice ? colorScheme.tertiarySystemBackground : colorScheme.secondarySystemBackground,
          padding: 8,
          cornerRadius: 5,
          isEnable: selection == nil,
          disableClickThrough: true)
        {
          Text(choice)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
            .foregroundColor(foregroundColor(for: choice, with: selection))
        }.opacity(opacity(for: choice, with: selection))
      }
    }
  }

  private func foregroundColor(for choice: String, with selection: String?) -> Color {
    guard let selection else { return .primary }
    return selection == choice ? .primary : .secondary
  }

  private func opacity(for choice: String, with selection: String?) -> Double {
    guard let selection else { return 1 }
    return selection == choice ? 1 : 0.4
  }

}
