// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ChatFeatureInterface
import ChatHistoryServiceInterface
import CheckpointServiceInterface
import Dependencies
import FileSuggestionServiceInterface
import Foundation
import JSONFoundation
import LLMServiceInterface
import ToolFoundation

// MARK: - ChatTabViewModel Extensions

extension ChatTabViewModel {
  convenience init(from persistentModel: ChatThreadModel) throws {
    try self.init(
      id: persistentModel.id,
      name: persistentModel.name,
      messages: persistentModel.messages.map { try .init(from: $0) },
      events: persistentModel.events.map { try .init(from: $0) },
      projectInfo: persistentModel.projectInfo,
      createdAt: persistentModel.createdAt)
  }

  var persistentModel: ChatThreadModel {
    .init(
      id: id,
      name: name,
      messages: messages.map(\.persistentModel),
      events: events.map(\.persistentModel),
      projectInfo: projectInfo,
      createdAt: createdAt)
  }

}

// MARK: - ChatMessage Extensions

extension ChatMessageViewModel {
  convenience init(from persistentModel: ChatMessageModel) throws {
    try self.init(
      id: persistentModel.id,
      content: persistentModel.content.map { try .init(from: $0) },
      role: persistentModel.role,
      timestamp: persistentModel.timestamp)
  }

  var persistentModel: ChatMessageModel {
    ChatMessageModel(
      id: id,
      content: content.map(\.persistentModel),
      role: role,
      timestamp: timestamp)
  }

}

// MARK: - ChatMessageContent Extensions

extension ChatMessageContent {
  @MainActor
  init(from persistentModel: ChatMessageContentModel) throws {
    switch persistentModel {
    case .text(let text):
      self = .text(.init(
        id: text.id,
        projectRoot: text.projectRoot,
        deltas: [text.text],
        attachments: text.attachments,
        isStreaming: false))

    case .reasoning(let reasoning):
      self = .reasoning(.init(id: reasoning.id, deltas: [reasoning.text], signature: reasoning.signature, isStreaming: false))

    case .nonUserFacingText(let nonUserFacingText):
      self = .nonUserFacingText(.init(
        id: nonUserFacingText.id,
        projectRoot: nonUserFacingText.projectRoot,
        deltas: [nonUserFacingText.text],
        attachments: nonUserFacingText.attachments,
        isStreaming: false))

    case .toolUse(let toolUseContent):
      let toolUse = toolUseContent.toolUse
      @Dependency(\.toolsPlugin) var toolsPlugin
      guard let tool = toolsPlugin.tool(named: toolUse.callingToolName) else {
        // TODO: better error handling
        throw AppError("Tool \(toolUse.callingToolName) not found")
      }
      self = try .toolUse(.init(
        id: toolUseContent.id,
        toolUse: tool.deserialize(
          toolUseId: toolUse.toolUseId,
          input: toolUse.input,
          context: toolUse.context,
          status: toolUse.status)))
    }
  }

  @MainActor
  var persistentModel: ChatMessageContentModel {
    switch self {
    case .text(let text):
      return .text(.init(id: text.id, projectRoot: text.projectRoot, text: text.text, attachments: text.attachments))

    case .reasoning(let reasoning):
      return .reasoning(.init(
        id: reasoning.id,
        text: reasoning.text,
        signature: reasoning.signature,
        reasoningDuration: reasoning.reasoningDuration))

    case .nonUserFacingText(let nonUserFacingText):
      return .nonUserFacingText(.init(
        id: nonUserFacingText.id,
        projectRoot: nonUserFacingText.projectRoot,
        text: nonUserFacingText.text,
        attachments: nonUserFacingText.attachments))

    case .toolUse(let toolUseContent):
      let toolUse = toolUseContent.toolUse
      let toolUseModel = ChatMessageToolUseContentModel.ToolUseModel(
        toolUseId: toolUse.toolUseId,
        input: (try? JSONEncoder().encode(toolUse.input)) ?? Data(),
        callingToolName: toolUse.callingTool.name,
        context: toolUse.context,
        status: toolUse.erasedStatus)
      return .toolUse(.init(id: toolUseContent.id, toolUse: toolUseModel))
    }
  }

}

// MARK: - ChatEvent Extensions

extension ChatEvent {
  @MainActor
  init(from persistentModel: ChatEventModel) throws {
    switch persistentModel {
    case .checkpoint(let checkpoint):
      self = .checkpoint(.init(
        id: checkpoint.id,
        message: checkpoint.message,
        projectRoot: checkpoint.projectRoot,
        taskId: checkpoint.taskId))

    case .message(let message):
      self = try .message(.init(content: .init(from: message.content), role: message.role, failureReason: message.failureReason))
    }
  }

  @MainActor
  var persistentModel: ChatEventModel {
    switch self {
    case .message(let message):
      .message(.init(content: message.content.persistentModel, role: message.role, failureReason: message.failureReason))

    case .checkpoint(let checkpoint):
      .checkpoint(.init(
        id: checkpoint.id,
        message: checkpoint.message,
        projectRoot: checkpoint.projectRoot,
        taskId: checkpoint.taskId))
    }
  }

}
