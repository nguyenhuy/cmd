// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - FileChange

public struct FileChange: Codable, Sendable {

  public init(
    filePath: URL,
    oldContent: String,
    suggestedNewContent: String,
    selectedChange: [LineChange],
    id: String = UUID().uuidString)
  {
    self.filePath = filePath
    self.oldContent = oldContent
    self.suggestedNewContent = suggestedNewContent
    self.selectedChange = selectedChange
    self.id = id
  }

  /// The file path of the file to change.
  public let filePath: URL
  /// The original content of the file.
  public let oldContent: String
  /// The suggested new content of the file. If the user selected only some of the suggested changes, the desired new content might be different.
  public let suggestedNewContent: String
  /// The change to apply, given line by line (remove / keep / add).
  /// Its references (line offset, character range) are relative to the old/new/new content.
  public let selectedChange: [LineChange]
  public let id: String

}

// MARK: - DiffContentType

public enum DiffContentType: String, Sendable, Codable {
  /// Content that is only present in the previous version.
  case removed
  /// Content that is only present in the new version.
  case added
  /// Content that is present in both versions. The range points to its location in the new version.
  case unchanged
}

// MARK: - LineChange

public struct LineChange: Sendable, Codable {
  public let characterRange: Range<Int>
  /// The line number where the change starts (0-indexed).
  public let lineOffset: Int
  public let content: String
  public let type: DiffContentType

  public init(_ lineOffset: Int, _ characterRange: Range<Int>, _ content: String, _ type: DiffContentType) {
    self.lineOffset = lineOffset
    self.characterRange = characterRange
    self.content = content
    self.type = type
  }

  public init(_ lineOffset: Int, _ characterRange: Range<Int>, _ content: String.SubSequence, _ type: DiffContentType) {
    self.lineOffset = lineOffset
    self.characterRange = characterRange
    self.content = String(content)
    self.type = type
  }
}
