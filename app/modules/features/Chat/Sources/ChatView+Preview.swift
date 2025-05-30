// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

#if DEBUG
#Preview {
  ChatView(viewModel: ChatViewModel(
    tabs: [
      ChatTabViewModel(messages: [
        ChatMessage(
          content: [.text(.init(
            projectRoot: URL(filePath: "/"),
            text: "What does this code do?",
            attachments: [
              .fileSelection(Attachment.FileSelectionAttachment(
                file: Attachment.FileAttachment(path: URL(filePath: "/Users/me/app/source.swift")!, content: mediumFileContent),
                startLine: 4,
                endLine: 10)),
            ]))],
          role: .user),
      ]),
    ])).frame(minHeight: 400)
}
#endif
