// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - Model Types

public struct ChatMessageModel: Codable, Identifiable, Sendable {
  public let id: String
  public let chatTabId: String
  public let role: String
  public let createdAt: Date
  public let updatedAt: Date

  public init(
    id: String,
    chatTabId: String,
    role: String,
    createdAt: Date = Date(),
    updatedAt: Date = Date())
  {
    self.id = id
    self.chatTabId = chatTabId
    self.role = role
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
