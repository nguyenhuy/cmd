// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatHistoryServiceInterface
import CheckpointServiceInterface
import FileSuggestionServiceInterface
import Foundation
import JSONFoundation
import LLMServiceInterface
import ToolFoundation

// MARK: - ChatTabViewModel Extensions

extension ChatTabViewModel {
  var persistentModel: ChatTabModel {
    ChatTabModel(
      id: id.uuidString,
      name: name,
      projectPath: projectInfo?.path.path,
      projectRootPath: projectInfo?.dirPath.path)
  }
}

// MARK: - ChatMessage Extensions

extension ChatMessage {
  static func from(persistentModel: ChatMessageModel, contents: [ChatMessageContent]) -> ChatMessage {
    ChatMessage(content: contents, role: MessageRole(rawValue: persistentModel.role) ?? .user)
  }

  func persistentModel(for chatTabId: String) -> ChatMessageModel {
    ChatMessageModel(
      id: id.uuidString,
      chatTabId: chatTabId,
      role: role.rawValue)
  }

}

// MARK: - ChatMessageContent Extensions

extension ChatMessageContent {
  @MainActor
  static func from(persistentModel: ChatMessageContentModel, attachments: [Attachment]) -> ChatMessageContent? {
    switch persistentModel.type {
    case "text":
      guard let text = persistentModel.text else { return nil }
      let projectRoot = persistentModel.projectRoot.map { URL(filePath: $0) }
      let textContent = ChatMessageTextContent(
        projectRoot: projectRoot,
        text: text,
        attachments: attachments,
        isStreaming: persistentModel.isStreaming)
      return .text(textContent)

    case "reasoning":
      guard let text = persistentModel.text else { return nil }
      let reasoningContent = ChatMessageReasoningContent(
        deltas: [text],
        signature: persistentModel.signature,
        isStreaming: persistentModel.isStreaming)
      if !persistentModel.isStreaming {
        reasoningContent.finishStreaming()
      }
      return .reasoning(reasoningContent)

    case "nonUserFacingText":
      guard let text = persistentModel.text else { return nil }
      let projectRoot = persistentModel.projectRoot.map { URL(filePath: $0) }
      let textContent = ChatMessageTextContent(
        projectRoot: projectRoot,
        text: text,
        attachments: attachments,
        isStreaming: persistentModel.isStreaming)
      return .nonUserFacingText(textContent)

    case "toolUse":
      // For tool use, we'd need to reconstruct the tool use object
      // This is complex because we need the original tool implementation
      // For now, we'll create a simple placeholder
      // TODO: Implement proper tool use reconstruction
      return nil

    default:
      return nil
    }
  }

  @MainActor
  func persistentModel(for messageId: String) -> ChatMessageContentModel {
    switch self {
    case .text(let textContent):
      return ChatMessageContentModel(
        id: id.uuidString,
        chatMessageId: messageId,
        type: "text",
        text: textContent.text,
        projectRoot: nil, // Skip project root for now due to private access
        isStreaming: textContent.isStreaming)

    case .reasoning(let reasoningContent):
      return ChatMessageContentModel(
        id: id.uuidString,
        chatMessageId: messageId,
        type: "reasoning",
        text: reasoningContent.text,
        isStreaming: reasoningContent.isStreaming,
        signature: reasoningContent.signature,
        reasoningDuration: reasoningContent.reasoningDuration)

    case .nonUserFacingText(let textContent):
      return ChatMessageContentModel(
        id: id.uuidString,
        chatMessageId: messageId,
        type: "nonUserFacingText",
        text: textContent.text,
        projectRoot: nil, // Skip project root for now due to private access
        isStreaming: textContent.isStreaming)

    case .toolUse(let toolUseContent):
      let toolInputJSON: String?
      do {
        let data = try JSONEncoder().encode(toolUseContent.toolUse.input)
        toolInputJSON = String(data: data, encoding: .utf8)
      } catch {
        toolInputJSON = nil
      }
      return ChatMessageContentModel(
        id: id.uuidString,
        chatMessageId: messageId,
        type: "toolUse",
        isStreaming: false,
        toolName: toolUseContent.toolUse.toolName,
        toolInput: toolInputJSON)
    }
  }

}

// MARK: - Attachment Extensions

extension Attachment {
  @MainActor
  static func from(persistentModel: AttachmentModel) -> Attachment? {
    switch persistentModel.type {
    case "file":
      guard
        let filePath = persistentModel.filePath,
        let fileContent = persistentModel.fileContent
      else { return nil }
      return .file(Attachment.FileAttachment(path: URL(filePath: filePath), content: fileContent))

    case "fileSelection":
      guard
        let filePath = persistentModel.filePath,
        let fileContent = persistentModel.fileContent,
        let startLine = persistentModel.startLine,
        let endLine = persistentModel.endLine
      else { return nil }
      return .fileSelection(Attachment.FileSelectionAttachment(
        file: Attachment.FileAttachment(path: URL(filePath: filePath), content: fileContent),
        startLine: startLine,
        endLine: endLine))

    case "image":
      guard let imageData = persistentModel.imageData else { return nil }
      let path = persistentModel.filePath.map { URL(filePath: $0) }
      return .image(Attachment.ImageAttachment(imageData: imageData, path: path))

    case "buildError":
      guard
        let filePath = persistentModel.filePath,
        let message = persistentModel.fileContent,
        let line = persistentModel.startLine,
        let column = persistentModel.endLine
      else { return nil }
      return .buildError(Attachment.BuildError(
        message: message,
        filePath: URL(filePath: filePath),
        line: line,
        column: column))

    default:
      return nil
    }
  }

  func persistentModel(for contentId: String) -> AttachmentModel {
    switch self {
    case .file(let file):
      AttachmentModel(
        id: UUID().uuidString,
        chatMessageContentId: contentId,
        type: "file",
        filePath: file.path.path,
        fileContent: file.content)

    case .fileSelection(let fileSelection):
      AttachmentModel(
        id: UUID().uuidString,
        chatMessageContentId: contentId,
        type: "fileSelection",
        filePath: fileSelection.file.path.path,
        fileContent: fileSelection.file.content,
        startLine: fileSelection.startLine,
        endLine: fileSelection.endLine)

    case .image(let imageAttachment):
      AttachmentModel(
        id: UUID().uuidString,
        chatMessageContentId: contentId,
        type: "image",
        filePath: imageAttachment.path?.path,
        imageData: imageAttachment.imageData)

    case .buildError(let buildError):
      AttachmentModel(
        id: UUID().uuidString,
        chatMessageContentId: contentId,
        type: "buildError",
        filePath: buildError.filePath.path,
        fileContent: buildError.message,
        startLine: buildError.line,
        endLine: buildError.column)
    }
  }

}

// MARK: - ChatEvent Extensions

extension ChatEvent {
  @MainActor
  static func from(persistentModel: ChatEventModel, messages: [ChatMessage]) -> ChatEvent? {
    switch persistentModel.type {
    case "message":
      guard
        let contentId = persistentModel.chatMessageContentId,
        let roleString = persistentModel.role,
        let role = MessageRole(rawValue: roleString)
      else { return nil }

      // Find the content in the loaded messages
      for message in messages {
        for content in message.content {
          if content.id.uuidString == contentId {
            let messageWithRole = ChatMessageContentWithRole(
              content: content,
              role: role,
              failureReason: persistentModel.failureReason)
            return .message(messageWithRole)
          }
        }
      }
      return nil

    case "checkpoint":
      guard let checkpointId = persistentModel.checkpointId else { return nil }
      // For now, create a minimal checkpoint since we don't have full checkpoint persistence
      // This would need to be extended to properly reconstruct checkpoints
      let checkpoint = Checkpoint(
        id: checkpointId,
        message: "Restored checkpoint",
        projectRoot: URL(filePath: "/"),
        taskId: "restored")
      return .checkpoint(checkpoint)

    default:
      return nil
    }
  }

  func persistentModel(for chatTabId: String, orderIndex: Int) -> ChatEventModel {
    switch self {
    case .message(let messageWithRole):
      ChatEventModel(
        id: id,
        chatTabId: chatTabId,
        type: "message",
        chatMessageContentId: messageWithRole.content.id.uuidString,
        role: messageWithRole.role.rawValue,
        failureReason: messageWithRole.failureReason,
        orderIndex: orderIndex)

    case .checkpoint(let checkpoint):
      ChatEventModel(
        id: id,
        chatTabId: chatTabId,
        type: "checkpoint",
        checkpointId: checkpoint.id,
        orderIndex: orderIndex)
    }
  }

}

// MARK: - Helper Types

extension MessageRole {
  init?(rawValue: String) {
    switch rawValue {
    case "user": self = .user
    case "assistant": self = .assistant
    case "system": self = .system
    case "tool": self = .tool
    default: return nil
    }
  }
}
