// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import FileDiffFoundation
import XcodeKit

// MARK: - XCSourceTextBuffer + XCSourceTextBufferI

extension XCSourceTextBuffer: @retroactive XCSourceTextBufferI {
  public func insert(line: String, at index: Int) {
    lines.insert(line, at: index)
  }

  public func removeLine(at index: Int) {
    lines.removeObject(at: index)
  }
}
