// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

public struct AttachmentModel: Codable, Identifiable, Sendable {
  public init(
    id: String,
    chatMessageContentId: String,
    type: String,
    filePath: String? = nil,
    fileContent: String? = nil,
    startLine: Int? = nil,
    endLine: Int? = nil,
    imageData: Data? = nil,
    createdAt: Date = Date())
  {
    self.id = id
    self.chatMessageContentId = chatMessageContentId
    self.type = type
    self.filePath = filePath
    self.fileContent = fileContent
    self.startLine = startLine
    self.endLine = endLine
    self.imageData = imageData
    self.createdAt = createdAt
  }

  public let id: String
  public let chatMessageContentId: String
  public let type: String
  public let filePath: String?
  public let fileContent: String?
  public let startLine: Int?
  public let endLine: Int?
  public let imageData: Data?
  public let createdAt: Date

}
