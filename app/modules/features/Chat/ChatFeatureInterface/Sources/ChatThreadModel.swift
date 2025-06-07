// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - ChatTabViewModel

public struct ChatThreadModel: Sendable {
  public init(
    id: String,
    name: String,
    messages: [ChatMessageModel],
    events: [ChatEventModel],
    projectInfo: SelectedProjectInfo?,
    createdAt: Date)
  {
    self.id = UUID(uuidString: id) ?? UUID()
    self.name = name
    self.messages = messages
    self.events = events
    self.projectInfo = projectInfo
    self.createdAt = createdAt
  }

  /// Information about the Xcode project/workspace/swift package that this thread is about.
  public struct SelectedProjectInfo: Sendable {
    /// The path to the project
    public let path: URL
    /// The dir containing the project (same as the path for a Swift Package)
    public let dirPath: URL

    public init(path: URL, dirPath: URL) {
      self.path = path
      self.dirPath = dirPath
    }
  }

  public let id: UUID
  public var name: String
  public var messages: [ChatMessageModel]
  public var events: [ChatEventModel]
  public var projectInfo: SelectedProjectInfo?
  public let createdAt: Date

}
