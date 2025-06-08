// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
import CheckpointServiceInterface
import Foundation
import LLMServiceInterface
import ToolFoundation

// MARK: - ChatThreadModel + Codable

extension ChatThreadModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      name: container.decode(String.self, forKey: .name),
      messages: container.decode([ChatMessageModel].self, forKey: .messages),
      events: container.decode([ChatEventModel].self, forKey: .events),
      projectInfo: container.decodeIfPresent(ChatThreadModel.SelectedProjectInfo.self, forKey: .projectInfo),
      createdAt: container.decode(Date.self, forKey: .createdAt))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(messages, forKey: .messages)
    try container.encode(events, forKey: .events)
    try container.encodeIfPresent(projectInfo, forKey: .projectInfo)
    try container.encode(createdAt, forKey: .createdAt)
  }

  enum CodingKeys: String, CodingKey {
    case id, name, messages, events, projectInfo, createdAt
  }
}

// MARK: - ChatThreadModel.SelectedProjectInfo + Codable

extension ChatThreadModel.SelectedProjectInfo: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      path: container.decode(URL.self, forKey: .path),
      dirPath: container.decode(URL.self, forKey: .dirPath))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(path, forKey: .path)
    try container.encode(dirPath, forKey: .dirPath)
  }

  enum CodingKeys: String, CodingKey {
    case path, dirPath
  }
}

// MARK: - ChatMessageModel + Codable

extension ChatMessageModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      content: container.decode([ChatMessageContentModel].self, forKey: .content),
      role: container.decode(MessageRole.self, forKey: .role),
      timestamp: container.decode(Date.self, forKey: .timestamp))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(content, forKey: .content)
    try container.encode(role, forKey: .role)
    try container.encode(timestamp, forKey: .timestamp)
  }

  enum CodingKeys: String, CodingKey {
    case id, content, role, timestamp
  }
}

// MARK: - ChatMessageContentWithRoleModel + Codable

extension ChatMessageContentWithRoleModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      content: container.decode(ChatMessageContentModel.self, forKey: .content),
      role: container.decode(MessageRole.self, forKey: .role),
      failureReason: container.decodeIfPresent(String.self, forKey: .failureReason))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(content, forKey: .content)
    try container.encode(role, forKey: .role)
    try container.encodeIfPresent(failureReason, forKey: .failureReason)
  }

  enum CodingKeys: String, CodingKey {
    case content, role, failureReason
  }
}

// MARK: - ChatMessageContentModel + Codable

extension ChatMessageContentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "text":
      let data = try container.decode(ChatMessageTextContentModel.self, forKey: .data)
      self = .text(data)

    case "reasoning":
      let data = try container.decode(ChatMessageReasoningContentModel.self, forKey: .data)
      self = .reasoning(data)

    case "nonUserFacingText":
      let data = try container.decode(ChatMessageTextContentModel.self, forKey: .data)
      self = .nonUserFacingText(data)

    case "toolUse":
      let data = try container.decode(ChatMessageToolUseContentModel.self, forKey: .data)
      self = .toolUse(data)

    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: container,
        debugDescription: "Unknown message content type: \(type)")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .text(let data):
      try container.encode("text", forKey: .type)
      try container.encode(data, forKey: .data)

    case .reasoning(let data):
      try container.encode("reasoning", forKey: .type)
      try container.encode(data, forKey: .data)

    case .nonUserFacingText(let data):
      try container.encode("nonUserFacingText", forKey: .type)
      try container.encode(data, forKey: .data)

    case .toolUse(let data):
      try container.encode("toolUse", forKey: .type)
      try container.encode(data, forKey: .data)
    }
  }

  enum CodingKeys: String, CodingKey {
    case type
    case data
  }

}

// MARK: - ChatMessageTextContentModel + Codable

extension ChatMessageTextContentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      projectRoot: container.decodeIfPresent(URL.self, forKey: .projectRoot),
      text: container.decode(String.self, forKey: .text),
      attachments: container.decode([AttachmentModel].self, forKey: .attachments))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(projectRoot, forKey: .projectRoot)
    try container.encode(text, forKey: .text)
    try container.encode(attachments, forKey: .attachments)
  }

  enum CodingKeys: String, CodingKey {
    case id, projectRoot, text, attachments
  }

}

// MARK: - ChatMessageToolUseContentModel + Codable

extension ChatMessageToolUseContentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let toolName = try container.decode(String.self, forKey: .toolName)
    guard let tool = try decoder.toolsPlugin.tool(named: toolName) else {
      throw DecodingError.dataCorruptedError(
        forKey: .toolName,
        in: container,
        debugDescription: "Tool with name '\(toolName)' not found in userInfo.toolPlugin.")
    }
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      toolUse: container.decode(useOf: tool, forKey: .toolUse))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(toolUse.toolName, forKey: .toolName)
    try container.encode(toolUse, forKey: .toolUse)
  }

  enum CodingKeys: String, CodingKey {
    case id, toolUse, toolName
  }

}

// MARK: - ChatMessageReasoningContentModel + Codable

extension ChatMessageReasoningContentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      text: container.decode(String.self, forKey: .text),
      signature: container.decodeIfPresent(String.self, forKey: .signature),
      reasoningDuration: container.decodeIfPresent(TimeInterval.self, forKey: .reasoningDuration))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(text, forKey: .text)
    try container.encodeIfPresent(signature, forKey: .signature)
    try container.encodeIfPresent(reasoningDuration, forKey: .reasoningDuration)
  }

  enum CodingKeys: String, CodingKey {
    case id, text, signature, reasoningDuration
  }

}

// extension ChatMessageToolUseContentModel.ToolUseModel: Codable {
//  public init(from decoder: any Decoder) throws {
//    let container = try decoder.container(keyedBy: CodingKeys.self)
//    try self.init(
//      toolUseId: container.decode(String.self, forKey: .toolUseId),
//      input: container.decode(Data.self, forKey: .input),
//      callingToolName: container.decode(String.self, forKey: .callingToolName),
//      context: container.decode(ToolExecutionContext.self, forKey: .context),
//      status: container.decode(ToolUseExecutionStatus<Data>.self, forKey: .status))
//  }
//
//  public func encode(to encoder: any Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//    try container.encode(toolUseId, forKey: .toolUseId)
//    try container.encode(input, forKey: .input)
//    try container.encode(callingToolName, forKey: .callingToolName)
//    try container.encode(context, forKey: .context)
//    try container.encode(status, forKey: .status)
//  }
//
//  enum CodingKeys: String, CodingKey {
//    case toolUseId, input, callingToolName, context, status
//  }
//
// }

// MARK: - ToolUseExecutionStatus + Codable

extension ToolUseExecutionStatus: Codable where Output: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: String.self)
    let type = try container.decode(String.self, forKey: "type")
    switch type {
    case "pendingApproval":
      self = .pendingApproval

    case "notStarted":
      self = .notStarted

    case "running":
      self = .running

    case "rejected":
      let reason = try container.decode(String.self, forKey: "reason")
      self = .rejected(reason: reason)

    case "completed":
      let resultType = try container.decode(String.self, forKey: "result_type")
      switch resultType {
      case "success":
        let output = try container.decode(Output.self, forKey: "result")
        self = .completed(.success(output))

      case "failure":
        let errorDescription = try container.decode(String.self, forKey: "result")
        let error = NSError(domain: "ToolUseExecutionStatus", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        self = .completed(.failure(error))

      default:
        throw DecodingError.dataCorruptedError(
          forKey: "result_type",
          in: container,
          debugDescription: "Unknown result type: \(resultType)")
      }

    default:
      throw DecodingError.dataCorruptedError(forKey: .init("type"), in: container, debugDescription: "Unknown type: \(type)")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: String.self)
    switch self {
    case .pendingApproval:
      try container.encode("pendingApproval", forKey: "type")

    case .notStarted:
      try container.encode("notStarted", forKey: "type")

    case .running:
      try container.encode("running", forKey: "type")

    case .rejected(reason: let reason):
      try container.encode("rejected", forKey: "type")
      try container.encode(reason, forKey: "reason")

    case .completed(let result):
      try container.encode("completed", forKey: "type")
      switch result {
      case .success(let output):
        try container.encode("success", forKey: "result_type")
        try container.encode(output, forKey: "result")

      case .failure(let error):
        try container.encode("failure", forKey: "result_type")
        try container.encode(error.localizedDescription, forKey: "result")
      }
    }
  }

}

// MARK: - MessageRole + Decodable

extension MessageRole: Decodable { }

// MARK: - ChatEventModel + Codable

extension ChatEventModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "message":
      let data = try container.decode(ChatMessageContentWithRoleModel.self, forKey: .data)
      self = .message(data)

    case "checkpoint":
      let data = try container.decode(Checkpoint.self, forKey: .data)
      self = .checkpoint(data)

    default:
      throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type: \(type)")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .message(let data):
      try container.encode("message", forKey: .type)
      try container.encode(data, forKey: .data)

    case .checkpoint(let data):
      try container.encode("checkpoint", forKey: .type)
      try container.encode(data, forKey: .data)
    }
  }

  enum CodingKeys: String, CodingKey {
    case type
    case data
  }

}

// MARK: - Checkpoint + Codable

extension Checkpoint: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(String.self, forKey: .id),
      message: container.decode(String.self, forKey: .message),
      projectRoot: container.decode(URL.self, forKey: .projectRoot),
      taskId: container.decode(String.self, forKey: .taskId))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(message, forKey: .message)
    try container.encode(projectRoot, forKey: .projectRoot)
    try container.encode(taskId, forKey: .taskId)
  }

  enum CodingKeys: String, CodingKey {
    case id, message, projectRoot, taskId
  }
}

// MARK: - AttachmentModel + Codable

extension AttachmentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "file":
      let data = try container.decode(FileAttachmentModel.self, forKey: .data)
      self = .file(data)

    case "image":
      let data = try container.decode(ImageAttachmentModel.self, forKey: .data)
      self = .image(data)

    case "fileSelection":
      let data = try container.decode(FileSelectionAttachmentModel.self, forKey: .data)
      self = .fileSelection(data)

    case "buildError":
      let data = try container.decode(BuildErrorModel.self, forKey: .data)
      self = .buildError(data)

    default:
      throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown attachment type: \(type)")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .file(let data):
      try container.encode("file", forKey: .type)
      try container.encode(data, forKey: .data)

    case .image(let data):
      try container.encode("image", forKey: .type)
      try container.encode(data, forKey: .data)

    case .fileSelection(let data):
      try container.encode("fileSelection", forKey: .type)
      try container.encode(data, forKey: .data)

    case .buildError(let data):
      try container.encode("buildError", forKey: .type)
      try container.encode(data, forKey: .data)
    }
  }

  enum CodingKeys: String, CodingKey {
    case type, data
  }
}

// MARK: - AttachmentModel.FileAttachmentModel + Codable

extension AttachmentModel.FileAttachmentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let attachmentSerializer = try decoder.attachmentSerializer
    let id = try container.decode(UUID.self, forKey: .id)
    try self.init(
      id: id,
      path: container.decode(URL.self, forKey: .path),
      content: attachmentSerializer.read(String.self, for: id))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let attachmentSerializer = try encoder.attachmentSerializer
    try container.encode(id, forKey: .id)
    try container.encode(path, forKey: .path)
    try attachmentSerializer.save(content, for: id)
  }

  enum CodingKeys: String, CodingKey {
    case id, path, content
  }
}

// MARK: - AttachmentModel.ImageAttachmentModel + Codable

extension AttachmentModel.ImageAttachmentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let attachmentSerializer = try decoder.attachmentSerializer
    let id = try container.decode(UUID.self, forKey: .id)
    try self.init(
      id: id,
      imageData: attachmentSerializer.read(Data.self, for: id),
      path: container.decodeIfPresent(URL.self, forKey: .path))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let attachmentSerializer = try encoder.attachmentSerializer
    try container.encode(id, forKey: .id)
    try container.encode(imageData, forKey: .imageData)
    try attachmentSerializer.save(imageData, for: id)
  }

  enum CodingKeys: String, CodingKey {
    case id, imageData, path
  }
}

// MARK: - AttachmentModel.FileSelectionAttachmentModel + Codable

extension AttachmentModel.FileSelectionAttachmentModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      file: container.decode(AttachmentModel.FileAttachmentModel.self, forKey: .file),
      startLine: container.decode(Int.self, forKey: .startLine),
      endLine: container.decode(Int.self, forKey: .endLine))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(file, forKey: .file)
    try container.encode(startLine, forKey: .startLine)
    try container.encode(endLine, forKey: .endLine)
  }

  enum CodingKeys: String, CodingKey {
    case id, file, startLine, endLine
  }
}

// MARK: - AttachmentModel.BuildErrorModel + Codable

extension AttachmentModel.BuildErrorModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: container.decode(UUID.self, forKey: .id),
      message: container.decode(String.self, forKey: .message),
      filePath: container.decode(URL.self, forKey: .filePath),
      line: container.decode(Int.self, forKey: .line),
      column: container.decode(Int.self, forKey: .column))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(message, forKey: .message)
    try container.encode(filePath, forKey: .filePath)
    try container.encode(line, forKey: .line)
    try container.encode(column, forKey: .column)
  }

  enum CodingKeys: String, CodingKey {
    case id, message, filePath, line, column
  }
}
