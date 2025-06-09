// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import GRDB

// MARK: - ChatThreadRecord

struct ChatThreadRecord: Codable, Identifiable, Sendable {
  init(
    id: String,
    name: String,
    createdAt: Date,
    rawContentPath: String)

  {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.rawContentPath = rawContentPath
  }

  let id: String
  let name: String
  let createdAt: Date
  let rawContentPath: String

}

// MARK: FetchableRecord, PersistableRecord

extension ChatThreadRecord: FetchableRecord, PersistableRecord {
  static let databaseTableName = "chat_threads"
}
