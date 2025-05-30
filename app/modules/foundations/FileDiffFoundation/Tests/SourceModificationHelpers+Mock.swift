// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@testable import FileDiffFoundation

// MARK: - MockSourceTextBuffer

final class MockXCSourceTextBufferI: XCSourceTextBufferI {

  init(text: String) {
    lines = text
      .splitLines()
      .map { String($0) }
  }

  var lines: [String]

  var completeBuffer: String {
    lines.joined()
  }

  func insert(line: String, at index: Int) {
    lines.insert(line, at: index)
  }

  func removeLine(at index: Int) {
    lines.remove(at: index)
  }

}
