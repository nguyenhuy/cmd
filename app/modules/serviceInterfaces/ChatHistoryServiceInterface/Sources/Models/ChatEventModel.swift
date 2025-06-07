// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
public struct ChatEventModel: Codable, Identifiable, Sendable {
  public init(
    id: String,
    chatTabId: String,
    type: String,
    chatMessageContentId: String? = nil,
    checkpointId: String? = nil,
    role: String? = nil,
    failureReason: String? = nil,
    createdAt: Date = Date(),
    orderIndex: Int)
  {
    self.id = id
    self.chatTabId = chatTabId
    self.type = type
    self.chatMessageContentId = chatMessageContentId
    self.checkpointId = checkpointId
    self.role = role
    self.failureReason = failureReason
    self.createdAt = createdAt
    self.orderIndex = orderIndex
  }

  public let id: String
  public let chatTabId: String
  public let type: String
  public let chatMessageContentId: String?
  public let checkpointId: String?
  public let role: String?
  public let failureReason: String?
  public let createdAt: Date
  public let orderIndex: Int

}
