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
    HStack(spacing: 12) {
      Text(request.toolName)
        .fontWeight(.medium)
      
      Spacer()
      IconsLabelButton(
        action: onDeny,
        systemNames: ["shift", "command", "delete.left"],
        label: "Reject")
      
      IconsLabelButton(
        action: onApprove,
        systemNames: ["command", "return"],
        label: "Allow Once")
      
      IconsLabelButton(
        action: onAlwaysApprove,
        systemNames: ["shift", "command", "enter"],
        label: "Always Allow")
    }
    .padding(16)
  }
}

// MARK: - Previews

#Preview {
  ToolApprovalView(
    request: ToolApprovalRequest(
      toolName: "get_workspace_info"
    ),
    onApprove: {},
    onDeny: {},
    onAlwaysApprove: {}
  )
}
