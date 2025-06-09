// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

// MARK: - XCSourceTextBufferI

/// A protocol similar to `XCSourceTextBuffer` that allows for mocking for tests,
/// and provides a more Swift friendly API.
public protocol XCSourceTextBufferI {
  var completeBuffer: String { get }

  func insert(line: String, at index: Int)

  func removeLine(at index: Int)
}
