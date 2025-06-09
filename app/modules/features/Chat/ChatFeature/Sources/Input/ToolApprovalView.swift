// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import DLS
import SwiftUI
import ToolFoundation

// MARK: - ToolApprovalView

struct ToolApprovalView: View {

  let request: ToolApprovalRequest
  let onApprove: () -> Void
  let onDeny: () -> Void
  let onAlwaysApprove: () -> Void

  var body: some View {
    VStack(alignment: .leading) {
      Text("**cmd** wants to use the *\(request.displayName)* tool")
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 12) {
        IconsLabelButton(
          action: onAlwaysApprove,
          systemNames: ["command", "shift", "return"],
          label: "Always Allow")
          .keyboardShortcut(.return, modifiers: [.shift, .command])

        IconsLabelButton(
          action: onApprove,
          systemNames: ["command", "return"],
          label: "Allow Once")
          .keyboardShortcut(.return, modifiers: .command)

        IconsLabelButton(
          action: onDeny,
          systemNames: ["command", "shift", "delete.left"],
          label: "Reject")
          .keyboardShortcut(.delete, modifiers: [.shift, .command])
      }
    }
    .padding(12)
  }
}

// MARK: - Previews

#Preview {
  ToolApprovalView(
    request: ToolApprovalRequest(
      toolName: "get_workspace_info",
      displayName: "Get Workspace Info"),
    onApprove: { },
    onDeny: { },
    onAlwaysApprove: { })
}
