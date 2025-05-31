// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
      Text(request.displayName)
        .fontWeight(.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 12) {
        IconsLabelButton(
          action: onDeny,
          systemNames: ["shift", "command", "delete.left"],
          label: "Reject")
        .keyboardShortcut(.delete, modifiers: [.shift, .command])
        
        IconsLabelButton(
          action: onApprove,
          systemNames: ["command", "return"],
          label: "Allow Once")
        .keyboardShortcut(.return, modifiers: .command)
        
        IconsLabelButton(
          action: onAlwaysApprove,
          systemNames: ["shift", "command", "return"],
          label: "Always Allow")
        .keyboardShortcut(.return, modifiers: [.shift, .command])
      }
    }
    .padding(12)
  }
}

// MARK: - Previews

#Preview {
  ToolApprovalView(
    request: ToolApprovalRequest(
      displayName: "get_workspace_info"
    ),
    onApprove: {},
    onDeny: {},
    onAlwaysApprove: {}
  )
}
