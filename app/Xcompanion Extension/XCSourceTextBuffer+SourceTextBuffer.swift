// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
