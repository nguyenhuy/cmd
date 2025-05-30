// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import SwiftUI

#if DEBUG
extension ChatMessageList {
  init(messages: [ChatMessage]) {
    self.init(events: messages.flatMap { message in
      message.content.map { .message(ChatMessageContentWithRole(content: $0, role: message.role)) }
    })
  }
}

/// A helper view to simulate streaming of chat messages.
struct DebugStreamingMessages: View {

  init(messages: [ChatMessage]) {
    self.messages = messages
  }

  var body: some View {
    VStack {
      HStack {
        Button("Stream one chunk") {
          _ = streamOneChunk()
        }
        Button("Stream all chunks") {
          Task {
            while streamOneChunk() {
              try await Task.sleep(nanoseconds: 50_000_000)
            }
          }
        }
        Button("Reset") {
          currentMessages.value = []
        }
      }.padding()
      ChatMessageList(messages: currentMessages.value)
    }
  }

  private let messages: [ChatMessage]
  @Bindable private var currentMessages = ObservableValue<[ChatMessage]>([])

  private func streamOneChunk() -> Bool {
    var currentMessages = currentMessages.value
    if let (i, currentMessage) = Array(currentMessages.enumerated()).last {
      if currentMessage.streamOneChunk(from: messages[i]) {
        return true
      }
    }
    // try to add new message
    let i = currentMessages.count
    if messages.count > i {
      currentMessages.append(ChatMessage(content: [], role: messages[i].role))
      self.currentMessages.value = currentMessages
      // Add some content to the new message.
      return streamOneChunk()
    }
    // Done streaming
    return false
  }
}

#Preview {
  ChatMessageList(messages: [
    ChatMessage(
      content: [.text(.init(text: "What does this code do?", attachments: [
        .fileSelection(Attachment.FileSelectionAttachment(
          file: Attachment.FileAttachment(path: URL(filePath: "/Users/me/app/source.swift")!, content: mediumFileContent),
          startLine: 4,
          endLine: 10)),
      ]))],
      role: .user),
    ChatMessage(
      content: [.text(.init(text: "Not much"))],
      role: .assistant),
    ChatMessage(
      content: [.text(.init(text: messageContentWithCode))],
      role: .assistant),
  ])
  .frame(maxWidth: 400, maxHeight: .infinity)
}

#Preview {
  DebugStreamingMessages(messages: [
    ChatMessage(
      content: [.text(.init(text: "What does this code do?", attachments: [
        .fileSelection(Attachment.FileSelectionAttachment(
          file: Attachment.FileAttachment(path: URL(filePath: "/Users/me/app/source.swift")!, content: mediumFileContent),
          startLine: 4,
          endLine: 10)),
      ]))],
      role: .user),
    ChatMessage(
      content: [.text(.init(text: "Not much"))],
      role: .assistant),
    ChatMessage(
      content: [.text(.init(text: messageContentWithCode))],
      role: .assistant),
  ])
  .frame(maxWidth: 400, maxHeight: .infinity)
}

#endif
