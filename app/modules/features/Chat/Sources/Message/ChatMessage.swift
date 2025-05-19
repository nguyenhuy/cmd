// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import LLMServiceInterface
import Observation
import ServerServiceInterface
import ToolFoundation

// MARK: - ChatMessage

@Observable
@MainActor
final class ChatMessage: EquatableByIdentifier {

  init(
    content: [ChatMessageContent],
    role: MessageRole)
  {
    self.content = content
    self.role = role
  }

  let id = UUID()
  var content: [ChatMessageContent]
  let role: MessageRole
  let timestamp = Date()
}

// MARK: - ChatMessageContent

enum ChatMessageContent: Identifiable {
  case text(ChatMessageTextContent)
  /// Messages that are relevant for the LLM but should not be shown to the user.
  case nonUserFacingText(ChatMessageTextContent)
  case toolUse(ChatMessageToolUseContent)

  var id: UUID {
    switch self {
    case .text(let content):
      content.id
    case .nonUserFacingText(let content):
      content.id
    case .toolUse(let content):
      content.id
    }
  }

  var asText: ChatMessageTextContent? {
    if case .text(let content) = self {
      return content
    }
    return nil
  }
}

// MARK: - ChatMessageContentWithRole

struct ChatMessageContentWithRole: Identifiable {
  let content: ChatMessageContent
  let role: MessageRole

  var id: UUID {
    content.id
  }
}

// MARK: - ChatMessageTextContent

@Observable
@MainActor
final class ChatMessageTextContent: EquatableByIdentifier {

  #if DEBUG
  convenience init(text: String, attachments: [Attachment] = []) {
    self.init(projectRoot: URL(filePath: "/"), text: text, attachments: attachments)
  }

  convenience init(deltas: [String], attachments: [Attachment] = []) {
    self.init(projectRoot: URL(filePath: "/"), deltas: deltas, attachments: attachments)
  }
  #endif

  init(projectRoot: URL, deltas: [String], attachments: [Attachment] = []) {
    self.attachments = attachments
    formatter = TextFormatter(projectRoot: projectRoot)
    catchUp(deltas: deltas)
  }

  init(projectRoot: URL, text: String, attachments: [Attachment] = []) {
    formatter = TextFormatter(projectRoot: projectRoot)
    self.attachments = attachments
    catchUp(deltas: [text])
  }

  let id = UUID()
  var attachments: [Attachment]

  private(set) var elements: [TextFormatter.Element] = []

  let formatter: TextFormatter

  var text: String {
    formatter.deltas.joined()
  }

  func catchUp(deltas: [String]) {
    formatter.catchUp(deltas: deltas)
    elements = formatter.elements
  }

  func ingest(delta: String) {
    formatter.ingest(delta: delta)
    elements = formatter.elements
  }

}

// MARK: - ChatMessageToolUseContent

@Observable
final class ChatMessageToolUseContent: EquatableByIdentifier {

  init(toolUse: any ToolUse) {
    self.toolUse = toolUse
  }

  let id = UUID()
  let toolUse: any ToolUse

}

// MARK: - EquatableByIdentifier

public protocol EquatableByIdentifier: Equatable, Identifiable { }

extension EquatableByIdentifier {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - MessageRole

enum MessageRole: String, Encodable {
  case user
  case assistant
  case system
}
