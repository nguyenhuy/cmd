// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import FileDiffFoundation
import FileDiffTypesFoundation

extension [LineChange] {
  var targetContent: String {
    targetContent(applying: self)
  }

  /// The selected content for the entire file, applying some specific suggested changes.
  func targetContent(applying selectedChanges: [LineChange]) -> String {
    var nextSelectedChangeIdx = 0

    var result = ""
    for line in self {
      if nextSelectedChangeIdx >= selectedChanges.count {
        // No more selected changes, keep the current content.
        if line.type != .added {
          result += line.content
        }
      } else {
        let nextSelectedChange = selectedChanges[nextSelectedChangeIdx]
        if line.type == nextSelectedChange.type, line.lineOffset == nextSelectedChange.lineOffset {
          // Apply the selected change. ie keep all but removed lines.
          if line.type != .removed {
            result += line.content
          }
          nextSelectedChangeIdx += 1
        } else {
          // Keep the current content. ie keep all but added lines.
          if line.type != .added {
            result += line.content
          }
        }
      }
    }

    return result
  }
}

extension [FormattedLineChange] {

  /// The suggested content for the entire file, rejecting some specific suggested changes.
  func suggestedContent(rejecting rejectedChanges: [FormattedLineChange]) -> [FormattedLineChange] {
    var nextRejectedChangeIdx = 0

    var result = [FormattedLineChange]()
    for line in self {
      if nextRejectedChangeIdx >= rejectedChanges.count {
        // No more selected changes, keep the suggested content.
        if line.change.type != .removed {
          result.append(line)
        }
      } else {
        let nextRejectedChange = rejectedChanges[nextRejectedChangeIdx]
        if line.change.type == nextRejectedChange.change.type, line.change.lineOffset == nextRejectedChange.change.lineOffset {
          // Keep the original content. ie keep all but added lines.
          if line.change.type != .added {
            result.append(.init(formattedContent: line.formattedContent, change: .init(
              line.change.lineOffset,
              line.change.characterRange,
              line.change.content,
              .unchanged)))
          }
          nextRejectedChangeIdx += 1
        } else {
          // Keep the suggested content. ie keep all but removed lines.
          if line.change.type != .removed {
            result.append(line)
          }
        }
      }
    }

    return result
  }
}
