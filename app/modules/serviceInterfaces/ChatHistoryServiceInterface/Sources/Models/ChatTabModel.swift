// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

public struct ChatTabModel: Codable, Identifiable, Sendable {
  public init(
    id: String,
    name: String,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    projectPath: String? = nil,
    projectRootPath: String? = nil)
  {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.projectPath = projectPath
    self.projectRootPath = projectRootPath
  }

  public let id: String
  public let name: String
  public let createdAt: Date
  public let updatedAt: Date
  public let projectPath: String?
  public let projectRootPath: String?

}
