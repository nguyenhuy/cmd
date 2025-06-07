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
    rawContentLocation: String)

  {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.rawContentLocation = rawContentLocation
  }

  let id: String
  let name: String
  let createdAt: Date
  let rawContentLocation: String

}

// MARK: FetchableRecord, PersistableRecord

extension ChatThreadRecord: FetchableRecord, PersistableRecord {
  static let databaseTableName = "chat_threads"
}
