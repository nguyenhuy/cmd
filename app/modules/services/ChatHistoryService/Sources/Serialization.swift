// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface
import Foundation

extension ChatThreadModel: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: String.self)
    try self.init(
      id: container.decode(String.self, forKey: "id"),
      name: container.decode(String.self, forKey: "name"),
      messages: container.decode([ChatMessageModel].self, forKey: "messages"),
      events: container.decode([ChatEventModel].self, forKey: "events"),
      projectInfo: container.decodeIfPresent(ChatThreadModel.ProjectInfo.self, forKey: "projectInfo"),
      createdAt: container.decode(Date.self, forKey: "createdAt"))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: String.self)
    try container.encode(id, forKey: "id")
    try container.encode(name, forKey: "name")
    try container.encode(messages, forKey: "messages")
    try container.encode(events, forKey: "events")
    try container.encodeIfPresent(projectInfo, forKey: "projectInfo")
    try container.encode(createdAt, forKey: "createdAt")
  }
}
