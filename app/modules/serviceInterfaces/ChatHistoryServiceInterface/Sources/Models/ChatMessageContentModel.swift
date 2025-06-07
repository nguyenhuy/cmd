// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

public struct ChatMessageContentModel: Codable, Identifiable, Sendable {
  public init(
    id: String,
    chatMessageId: String,
    type: String,
    text: String? = nil,
    projectRoot: String? = nil,
    isStreaming: Bool = false,
    signature: String? = nil,
    reasoningDuration: Double? = nil,
    toolName: String? = nil,
    toolInput: String? = nil,
    toolResult: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date())
  {
    self.id = id
    self.chatMessageId = chatMessageId
    self.type = type
    self.text = text
    self.projectRoot = projectRoot
    self.isStreaming = isStreaming
    self.signature = signature
    self.reasoningDuration = reasoningDuration
    self.toolName = toolName
    self.toolInput = toolInput
    self.toolResult = toolResult
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public let id: String
  public let chatMessageId: String
  public let type: String
  public let text: String?
  public let projectRoot: String?
  public let isStreaming: Bool
  public let signature: String?
  public let reasoningDuration: Double?
  public let toolName: String?
  public let toolInput: String?
  public let toolResult: String?
  public let createdAt: Date
  public let updatedAt: Date

}
