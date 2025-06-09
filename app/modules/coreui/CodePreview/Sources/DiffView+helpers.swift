// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import FileDiffFoundation

extension [FormattedLineChange] {
  /// Identifies and groups consecutive changes in a diff into sections.
  /// This can be used to identify which content is far enough from a change that it can be hidden.
  ///
  /// - Parameter minSeparation: The minimum number of unchanged lines required to separate two diff sections.
  /// - Returns: An array of ranges where each range represents a section of consecutive changes.
  ///
  /// A section is defined as any group of changed lines (added/removed) where no two adjacent changes
  /// are separated by more than `minSeparation` unchanged lines. Each section includes up to
  /// `minSeparation` unchanged lines before the first change and after the last change to provide context.
  func changedSection(minSeparation: Int) -> [Range<Int>] {
    var partialDiffRanges = [Range<Int>]()

    var l = 0
    var rangeStart: Int?
    var lastUnchangedLine: Int?
    while l < count {
      if self[l].change.type != .unchanged {
        lastUnchangedLine = l
        rangeStart = rangeStart ?? Swift.max(0, l - minSeparation)
      } else if
        let start = rangeStart, let end = lastUnchangedLine,
        l - end > 2 * minSeparation
      {
        partialDiffRanges.append(start..<l - minSeparation)
        rangeStart = nil
        lastUnchangedLine = nil
      }
      l += 1
    }
    // add final range if necessary
    if
      let rangeStart
    {
      partialDiffRanges.append(rangeStart..<count)
    }
    return partialDiffRanges.map { $0.clamped(to: 0..<count) }
  }

  func continousChanges(in range: Range<Int>) -> [Range<Int>] {
    var changes = [Range<Int>]()
    var start = range.lowerBound
    while true {
      // Move start to the next change.
      while start < range.upperBound, self[start].change.type == .unchanged {
        start += 1
      }
      if start == range.upperBound {
        break
      }

      var end = start
      // Move end to the next unchanged line.
      while end < range.upperBound, self[end].change.type != .unchanged {
        end += 1
      }
      changes.append(start..<end)
      if end == range.upperBound {
        break
      }
      start = end + 1
    }
    return changes
  }

}

extension Range<Int> {
  var id: String {
    "\(lowerBound)-\(upperBound)"
  }
}
