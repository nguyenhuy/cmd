// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import LLMServiceInterface

// MARK: - ChatMessageModel

public struct ChatMessageModel: Sendable {

  public init(
    id: String,
    content: [ChatMessageContentModel],
    role: MessageRole,
    timestamp: Date)
  {
    self.id = UUID(uuidString: id) ?? UUID()
    self.content = content
    self.role = role
    self.timestamp = timestamp
  }

  public let id: UUID
  public let content: [ChatMessageContentModel]
  public let role: MessageRole
  public let timestamp: Date
}

// MARK: - ChatMessageContentWithRoleModel

public struct ChatMessageContentWithRoleModel: Sendable {
  public init(
    content: ChatMessageContentModel,
    role: MessageRole,
    failureReason: String? = nil)
  {
    self.content = content
    self.role = role
    self.failureReason = failureReason
  }

  public let content: ChatMessageContentModel
  public let role: MessageRole
  public let failureReason: String?
}

// MARK: - ChatMessageContentModel

public enum ChatMessageContentModel: Sendable {
  case text(ChatMessageTextContentModel)
  case reasoning(ChatMessageReasoningContentModel)
  /// Messages that are relevant for the LLM but should not be shown to the user.
  case nonUserFacingText(ChatMessageTextContentModel)
  case toolUse(ChatMessageToolUseContentModel)
}

// MARK: - ChatMessageTextContentModel

public final class ChatMessageTextContentModel: Identifiable, Sendable {

  public init(id: String, projectRoot: URL?, text: String, attachments: [AttachmentModel]) {
    self.id = UUID(uuidString: id) ?? UUID()
    self.projectRoot = projectRoot
    self.text = text
    self.attachments = attachments
  }

  public let id: UUID
  public let projectRoot: URL?
  public let text: String
  public let attachments: [AttachmentModel]

}

// MARK: - ChatMessageToolUseContentModel

public final class ChatMessageToolUseContentModel: Identifiable, Sendable {

  public init(id: String, toolUse: String) {
    self.id = UUID(uuidString: id) ?? UUID()
    self.toolUse = toolUse
  }

  public let id: UUID
  public let toolUse: String

}

// MARK: - ChatMessageReasoningContentModel

public final class ChatMessageReasoningContentModel: Identifiable, Sendable {

  public init(id: String, text: String, signature: String?, reasoningDuration: TimeInterval?) {
    self.id = UUID(uuidString: id) ?? UUID()
    self.text = text
    self.signature = signature
    self.reasoningDuration = reasoningDuration
  }

  public let id: UUID
  public let text: String
  public let signature: String?
  public let reasoningDuration: TimeInterval?

}

// MARK: - MessageRole

public enum MessageRole: String, Encodable, Sendable {
  case user
  case assistant
  case system
  case tool
}
