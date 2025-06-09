// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
