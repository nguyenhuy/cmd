// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import ConcurrencyFoundation
import Dependencies
import FileDiffFoundation
import FileDiffTypesFoundation
import FileEditServiceInterface
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import SwiftTesting
import Testing
@testable import CodePreview

struct SuggestedFileChangeTests {
  var filePath: URL {
    URL(filePath: "/dir/test.swift")
  }

  var mockFileRef: MockFileReference {
    MockFileReference(path: filePath, currentContent: "Hello\nWorld")
  }

  @Test("Initializes with valid changes")
  @MainActor
  func test_initialization() async throws {
    await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change != nil)
      #expect(change?.baseLineContent == "Hello\nWorld")
      #expect(change?.targetContent == "Hi\nWorld")
      #expect(change?.canBeApplied == true)
    }
  }

  @Test("Returns nil when changes don't modify content")
  func test_noChanges() async throws {
    await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hello
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change == nil)
    }
  }

  @Test("Handles file content changes")
  @MainActor
  func test_fileContentChanges() async throws {
    try await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef },
        onSubscribeToContentChange: { _, callback in
          callback("New\nWorld")
        })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change != nil)
      #expect(change?.baseLineContent == "Hello\nWorld")
      #expect(change?.targetContent == "Hi\nWorld")
      #expect(change?.canBeApplied == true)

      // Wait for the content change to be processed
      try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

      // Verify that the change was rebased correctly
      #expect(change?.canBeApplied == true)
      #expect(change?.formattedDiff.changes.map(\.change).targetContent == "Hi\nWorld")
    }
  }

  @Test("Applies changes correctly")
  func test_applyChanges() async throws {
    let mockFileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])

    let applyExpectation = expectation(description: "Changes applied")
    let mockFileEditService = MockFileEditService(
      currentContent: "Hello\nWorld",
      onTrackChangesOfFile: { _ in mockFileRef },
      onApply: { change in
        try await Task {
          #expect(change.filePath.path == filePath.path)
          #expect(change.oldContent == "Hello\nWorld")
          #expect(change.suggestedNewContent == "Hi\nWorld")
          try mockFileManager.write(string: "Hi\nWorld", to: filePath, options: [])
          applyExpectation.fulfill()
        }.value
      })
    try await withDependencies {
      $0.fileManager = mockFileManager
      $0.fileEditService = mockFileEditService
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      try await change?.handleApplyAllChange()
      try await fulfillment(of: [applyExpectation], timeout: 1.0)

      // Verify the file content was updated
      let updatedContent = try mockFileManager.read(contentsOf: filePath, encoding: .utf8)
      #expect(updatedContent == "Hi\nWorld")
    }
  }

  @Test("Rejects changes correctly")
  @MainActor
  func test_rejectChanges() async throws {
    try await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let suggestedChange = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      let change = try #require(suggestedChange)
      #expect(change.targetContent == "Hi\nWorld")

      await change.handleReject(changes: change.formattedDiff.changes)
      #expect(change.targetContent == "Hello\nWorld")
      #expect(change.formattedDiff.changes.map(\.change).targetContent == "Hello\nWorld")
    }
  }

  @Test("Reapplies changes correctly")
  @MainActor
  func test_reapplyChanges() async throws {
    await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change != nil)
      #expect(change?.targetContent == "Hi\nWorld")

      await change?.handleReapplyChange()
      #expect(change?.targetContent == "Hi\nWorld")
      #expect(change?.baseLineContent == "Hello\nWorld")
      #expect(change?.canBeApplied == true)
      #expect(change?.formattedDiff.changes.map(\.change).targetContent == "Hi\nWorld")
    }
  }

  // @Test("Updates state when file content changes on disk and does not conflict")
  // func test_fileContentChangeOnDisk() async throws {
  //   let contentChangeExpectation = expectation(description: "Content change processed")
  //   let stateUpdateExpectation = expectation(description: "State updated")
  //   let baselineContent = """
  //     Hello
  //     World

  //     All
  //     is
  //     Good
  //     """

  //   try await withDependencies {
  //     $0.fileManager = MockFileManager(files: [filePath.path(): baselineContent])
  //     $0.fileEditService = MockFileEditService(
  //       currentContent: baselineContent,
  //       onTrackChangesOfFile: { _ in MockFileReference(path: filePath, currentContent: baselineContent) },
  //       onSubscribeToContentChange: { _, callback in
  //         Task {
  //           // Simulate file content being updated on disk
  //           callback(baselineContent.replacingOccurrences(of: "Good", with: "Great"))
  //           contentChangeExpectation.fulfill()
  //         }
  //       })
  //   } operation: {
  //     let llmDiff = """
  //       <<<<<<< SEARCH
  //       Hello
  //       =======
  //       Hi
  //       >>>>>>> REPLACE
  //       """

  //     let change = await SuggestedFileChange(
  //       filePath: filePath.path(),
  //       llmDiff: llmDiff)

  //     #expect(change != nil)
  //     #expect(change?.baseLineContent == baselineContent)
  //     #expect(change?.targetContent == baselineContent.replacingOccurrences(of: "Hello", with: "Hi"))
  //     #expect(change?.canBeApplied == true)

  //     // Use polling here, as there's no good way to subscribe to an update to an @Observable object.
  //     Task {
  //       while change?.baseLineContent.contains("Great") != true {
  //         try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
  //       }
  //       stateUpdateExpectation.fulfill()
  //     }

  //     try await fulfillment(of: [contentChangeExpectation, stateUpdateExpectation])

  //     #expect(change?.canBeApplied == true)
  //     #expect(change?.formattedDiff.changes.map(\.change).targetContent == """
  //       Hi
  //       World

  //       All
  //       is
  //       Great
  //       """)
  //   }
  // }

  @Test("Updates state when file content changes on disk and conflicts")
  @MainActor
  func test_fileContentChangeOnDiskConflicts() async throws {
    let contentChangeExpectation = expectation(description: "Content change processed")
    let stateUpdateExpectation = expectation(description: "State updated")

    try await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
      $0.fileEditService = MockFileEditService(
        currentContent: "Hello\nWorld",
        onTrackChangesOfFile: { _ in mockFileRef },
        onSubscribeToContentChange: { _, callback in
          Task {
            // Simulate file content being updated on disk
            callback("Updated\nWorld")
            contentChangeExpectation.fulfill()
          }
        })
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change != nil)
      #expect(change?.baseLineContent == "Hello\nWorld")
      #expect(change?.targetContent == "Hi\nWorld")
      #expect(change?.canBeApplied == true)

      // Use polling here, as there's no good way to subscribe to an update to an @Observable object.
      Task {
        while change?.baseLineContent != "Updated\nWorld" {
          try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        }
        stateUpdateExpectation.fulfill()
      }

      try await fulfillment(of: [contentChangeExpectation, stateUpdateExpectation])

      #expect(change?.baseLineContent == "Updated\nWorld")
      #expect(change?.canBeApplied == false)
      #expect(change?.formattedDiff.changes.map(\.change).targetContent == """
        <<<<<<< HEAD
        Updated
        =======
        Hi
        >>>>>>> suggestion
        World
        """)
    }
  }
}
