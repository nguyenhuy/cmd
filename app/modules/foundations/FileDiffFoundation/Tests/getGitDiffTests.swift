// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppKit
import Foundation
import Testing
@testable import FileDiffFoundation

struct GetGitDiffTests {
  @Test("Git diff with no changes")
  func test_gitDiffWithNoChanges() async throws {
    let oldContent = """
      static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bashrc"
        task.standardInput = nil
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
      }
      """
    let newContent = """
      /// Run a shell command and return the output as a string.
      /// Doesn't handle errors.
      static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
      }
      """
    let gitDiff = try FileDiff.getGitDiff(oldContent: oldContent, newContent: newContent)
    #expect(
      gitDiff.trimmingCharacters(in: .whitespacesAndNewlines) == """
        @@ -1,3 +1,5 @@
        +/// Run a shell command and return the output as a string.
        +/// Doesn\'t handle errors.
         static func shell(_ command: String) -> String {
           let task = Process()
           let pipe = Pipe()
        @@ -5,7 +7,7 @@ static func shell(_ command: String) -> String {
           task.standardOutput = pipe
           task.standardError = pipe
           task.arguments = [\"-c\", command]
        -  task.launchPath = \"/bin/bashrc\"
        +  task.launchPath = \"/bin/zsh\"
           task.standardInput = nil
           task.launch()
        """)
  }

  @Test("Git diff with multiple changes")
  func test_gitDiffWithMultipleChanges() async throws {
    let oldContent = """
      func hello() {
        print("Hello")
        return
      }
      """
    let newContent = """
      func hello(name: String) {
        print("Hello \\(name)!")
      }
      """

    let gitDiff = try FileDiff.getGitDiff(oldContent: oldContent, newContent: newContent)
    #expect(gitDiff.contains("-  print(\"Hello\")"))
    #expect(gitDiff.contains("+  print(\"Hello \\(name)!\")"))
  }

  @Test("Git diff with empty content")
  func test_gitDiffWithEmptyContent() async throws {
    let oldContent = ""
    let newContent = "Hello World"

    let gitDiff = try FileDiff.getGitDiff(oldContent: oldContent, newContent: newContent)
    #expect(gitDiff.contains("+Hello World"))
  }
}
