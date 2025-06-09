// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppFoundation
import FileDiffTypesFoundation
import Foundation
import LoggingServiceInterface

// MARK: - SourceModificationHelpers

public enum SourceModificationHelpers {
  public static func update(buffer: XCSourceTextBufferI, with fileChange: FileDiffTypesFoundation.FileChange) throws {
    guard buffer.completeBuffer == fileChange.oldContent else {
      let debugMessageData = try? JSONSerialization.data(withJSONObject: [
        "bufferContent": buffer.completeBuffer,
        "expectedContent": fileChange.oldContent,
      ])
      let debugDescription = debugMessageData.flatMap { String(data: $0, encoding: .utf8) }
      throw AppError(message: "Editor's content does not match the code to modify.", debugDescription: debugDescription)
    }
    var lineOffset = 0
    for lineChange in fileChange.selectedChange {
      switch lineChange.type {
      case .added:
        buffer.insert(line: lineChange.content, at: lineOffset)
        lineOffset += 1

      case .removed:
        buffer.removeLine(at: lineOffset)

      case .unchanged:
        lineOffset += 1
        break
      }
    }
  }

}

extension Array {
  func at(_ index: Int) throws -> Element {
    guard index >= 0, index < count else {
      throw AppError(message: "Index \(index) out of bounds [0, \(count) [")
    }
    return self[index]
  }
}

extension String.SubSequence {
  /// Splits the collection into substrings that each represent a line of text.
  func splitLines()
    -> [String.SubSequence]
  {
    var result = [String.SubSequence]()
    var lineStart = startIndex
    var index = startIndex
    while index < endIndex {
      if self[index] == "\n" {
        result.append(self[lineStart...index])
        lineStart = self.index(after: index)
      }
      index = self.index(after: index)
    }
    if lineStart != endIndex {
      result.append(self[lineStart...])
    } else if !isEmpty {
      result.append(self[lineStart..<lineStart])
    }
    return result
  }
}

extension String {
  func splitLines() -> [String.SubSequence] {
    self[...].splitLines()
  }
}
