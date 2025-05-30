// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Dependencies
import FoundationInterfaces
import JSONFoundation
import SwiftUI
import ToolFoundation

#if DEBUG
struct TestTool: NonStreamableTool {
  public func isAvailable(in _: ChatMode) -> Bool {
    true
  }

  struct Use: ToolUse {
    public let isReadonly = true
    init(input: String = "") {
      self.input = input
      callingTool = TestTool()
      status = ConcurrencyFoundation.CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<String>>
        .Just(.completed(.success(input)))
      toolUseId = UUID().uuidString
    }

    let input: String

    let callingTool: TestTool

    var status: ConcurrencyFoundation.CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<String>>

    let toolUseId: String

    func startExecuting() { }

  }

  var inputSchema = JSON.object([:])

  var name: String { "TestTool" }
  var description: String { "A tool for testing." }

  func use(toolUseId _: String, input _: String, context _: ToolExecutionContext) -> Use {
    Use()
  }

}

let messageContentWithCode = """
  Hi try this code. I left a very long explanation for the purpose of demonstrating how very long lines get displayed.
  ```swift
  // an extremely long description of this function that simply adds two integers together, because it's a very complex operation that requires a lot of explanation.
  func add(a: Int, b: Int) -> Int {
    a + b
  }
  ```
  """

let messageContentWithCodeDiff = """
  Hi try this code.
  ```swift:/path/to/file.swift
  <<<<<<< SEARCH
  Hello, world!
  =======
  Hello, universe!
  >>>>>>> REPLACE
  ```
  """

let messageContentWithUnfinishedCode = """
   Hi try this
   ```
   func add(a: Int, b: Int) -> Int {
     a 
  """

let messageContentWithLongCode = """
  Hi try this code. It's a bit long but should work well
  ```
  // an extremely long description of this function that simply adds two integers together, because it's a very complex operation that requires a lot of explanation.
  func add(a: Int, b: Int) -> Int {
    a + b
  }
  func sub(a: Int, b: Int) -> Int {
    a - b
  }
  func mul(a: Int, b: Int) -> Int {
    a * b
  }
  func div(a: Int, b: Int) -> Int {
    a / b
  }
  func mod(a: Int, b: Int) -> Int {
    a % b
  }
  func pow(a: Int, b: Int) -> Int {
    a ** b
  }
  ```
  """

extension ChatMessage {
  /// For debug puspose only.
  /// Simulate streaming of a chat message by adding one chunk of text content at a time.
  /// Chunks are automatically generated from the desired message content.
  @MainActor
  func streamOneChunk(from desiredMessage: ChatMessage) -> Bool {
    if let (j, content) = Array(content.enumerated()).last {
      if case .text(let text) = content {
        let desiredTextContent = desiredMessage.content[j].asText!.text
        if desiredTextContent != text.text {
          // Last message content is a text that is not fully streamed. Add one chunk.
          let missingText = desiredTextContent.suffix(desiredTextContent.count - text.text.count)
          let nextChunk = missingText.prefix(5)
          text.ingest(delta: String(nextChunk))
          return true
        }
      }
    }
    // try to add new content
    let j = content.count
    if desiredMessage.content.count > j {
      if case .text(let text) = desiredMessage.content[j] {
        // Add a new text content.
        content.append(.text(ChatMessageTextContent(deltas: [], attachments: text.attachments)))
        // Add a chunk of text to the new content.
        return streamOneChunk(from: desiredMessage)
      } else {
        // Tool use etc. Add the entire content directly.
        content.append(desiredMessage.content[j])
      }
      return true
    }
    return false
  }
}

/// A helper view to simulate streaming of chat messages.
struct DebugStreamingMessage: View {

  init(message: ChatMessage) {
    self.message = message
    currentMessage = ChatMessage(content: [], role: message.role)
  }

  var body: some View {
    VStack {
      HStack {
        Button("Stream one chunk") {
          _ = currentMessage.streamOneChunk(from: message)
        }
        Button("Stream all chunks") {
          Task {
            while currentMessage.streamOneChunk(from: message) {
              try await Task.sleep(nanoseconds: 50_000_000)
            }
          }
        }
        Button("Reset") {
          currentMessage.content = []
        }
      }.padding()
      ForEach(currentMessage.content) { content in
        ChatMessageView(message: .init(content: content, role: currentMessage.role))
      }
    }
  }

  private let message: ChatMessage
  @Bindable private var currentMessage: ChatMessage
}

#Preview {
  ScrollView {
    VStack {
      ChatMessageView(message: ChatMessageContentWithRole(
        content: .text(.init(text: "What does this code do?", attachments: [
          .fileSelection(Attachment.FileSelectionAttachment(
            file: Attachment.FileAttachment(path: URL(filePath: "/Users/me/app/source.swift")!, content: mediumFileContent),
            startLine: 4,
            endLine: 10)),
        ])),
        role: .user))

      ChatMessageView(message: ChatMessageContentWithRole(
        content: .text(.init(text: "Not much")),
        role: .assistant))

      ChatMessageView(message: ChatMessageContentWithRole(
        content: .text(.init(text: """
          # This is some Markdown
          * This is a list item

          ## This is a subheading

          This is a paragraph with a [link](https://www.google.com).

          This is a paragraph with a ![image](https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png).

          This is a paragraph with a `code` inline.

          """)),
        role: .assistant))

      ChatMessageView(message: ChatMessageContentWithRole(
        content: .text(.init(text: messageContentWithCode)),
        role: .assistant))

      withDependencies({
        $0.fileManager = MockFileManager(files: [
          "/path/to/file.swift": """
            Hello, world!
            What a wonderful world!
            So lucky to be here!
            """,
        ])
      }, operation: {
        VStack {
          ChatMessageView(message: ChatMessageContentWithRole(
            content:
            .text(.init(text: messageContentWithCodeDiff)),
            role: .assistant))

          ChatMessageView(message: ChatMessageContentWithRole(
            content:
            .toolUse(.init(toolUse: TestTool.Use())),
            role: .assistant))
        }
      })

      ChatMessageView(message: ChatMessageContentWithRole(
        content: .text(.init(text: messageContentWithUnfinishedCode)),
        role: .assistant))

      DebugStreamingMessage(message: ChatMessage(
        content: [.text(.init(text: messageContentWithLongCode))],
        role: .assistant))
      Spacer()
    }
  }
  .frame(maxWidth: 400, minHeight: 700, maxHeight: 700)
  .padding()
}

#endif
