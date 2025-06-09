// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import SwiftUI

#if DEBUG
typealias SearchFilesStatus = AskFollowUpTool.Use.Status

#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.running),
        input: AskFollowUpTool.Input(
          question: "Can edit this file?", followUp: [
            "Yes",
            "No",
          ]),
        selectFollowUp: { _ in }))

      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.notStarted),
        input: AskFollowUpTool.Input(
          question: "Can edit this file?", followUp: [
            "Yes",
            "No",
          ]),
        selectFollowUp: { _ in }))

      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.completed(.success(AskFollowUpTool.Use.Output(response: "Yes")))),
        input: AskFollowUpTool.Input(
          question: "Can edit this file?", followUp: [
            "Yes",
            "No",
            "Maybe",
            "I'm not sure",
            "Try and see",
          ]),
        selectFollowUp: { _ in }))
    }
  }
  .frame(width: 100, height: 200)
  .padding()
}
#endif
