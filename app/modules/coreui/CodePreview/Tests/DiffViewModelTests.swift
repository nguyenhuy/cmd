// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import ConcurrencyFoundation
import Dependencies
import FileDiffFoundation
import FileDiffTypesFoundation
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import SwiftTesting
import Testing
import XcodeControllerServiceInterface
@testable import CodePreview

struct FileDiffViewModelTests {
  var filePath: URL {
    URL(filePath: "/dir/test.swift")
  }

  @MainActor
  @Test("Initializes with valid changes")
  func test_initialization() async throws {
    let change = withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      return FileDiffViewModel(
        filePath: filePath.path(),
        llmDiff: llmDiff)
    }

    #expect(change != nil)
    #expect(change?.baseLineContent == "Hello\nWorld")
    #expect(await change?.targetContent == "Hi\nWorld")
    #expect(change?.canBeApplied == true)
  }

  @MainActor
  @Test("Returns nil when changes don't modify content")
  func test_noChanges() async throws {
    withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hello
        >>>>>>> REPLACE
        """

      let change = FileDiffViewModel(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      #expect(change == nil)
    }
  }

  @MainActor
  @Test("Applies changes correctly")
  func test_applyChanges() async throws {
    let mockFileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])

    let applyExpectation = expectation(description: "Changes applied")
    let mockXcodeController = MockXcodeController()
    mockXcodeController.onApplyFileChange = { change in
      #expect(change.filePath.path == filePath.path)
      #expect(change.oldContent == "Hello\nWorld")
      #expect(change.suggestedNewContent == "Hi\nWorld")
      try? mockFileManager.write(string: "Hi\nWorld", to: filePath, options: [])
      applyExpectation.fulfill()
    }
    try await withDependencies {
      $0.fileManager = mockFileManager
      $0.xcodeController = mockXcodeController
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let change = FileDiffViewModel(
        filePath: filePath.path(),
        llmDiff: llmDiff)

      try await waitForInitialization(of: change)

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
    let change = try await withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
    } operation: {
      let llmDiff = """
        <<<<<<< SEARCH
        Hello
        =======
        Hi
        >>>>>>> REPLACE
        """

      let suggestedChange = FileDiffViewModel(
        filePath: filePath.path(),
        llmDiff: llmDiff)
      try await waitForInitialization(of: suggestedChange)

      return try #require(suggestedChange)
    }
    #expect(await change.targetContent == "Hi\nWorld")
    let formattedDiff = try #require(change.formattedDiff)

    try change.handleReject(changes: formattedDiff.changes)
    #expect(await change.targetContent == "Hello\nWorld")
    #expect(change.formattedDiff?.changes.map(\.change).targetContent == "Hello\nWorld")
  }

//  @Test("Reapplies changes correctly")
//  @MainActor
//  func test_reapplyChanges() async throws {
//    try await withDependencies {
//      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
//      $0.fileEditService = MockFileEditService(
//        currentContent: "Hello\nWorld",
//        onTrackChangesOfFile: { _ in mockFileRef })
//    } operation: {
//      let llmDiff = """
//        <<<<<<< SEARCH
//        Hello
//        =======
//        Hi
//        >>>>>>> REPLACE
//        """
//
//      let change = FileDiffViewModel(
//        filePath: filePath.path(),
//        llmDiff: llmDiff)
//
//      #expect(change != nil)
//      #expect(change?.targetContent == "Hi\nWorld")
//
//        let exp1 = expectation(description: "State updated once")
//        let exp2 = expectation(description: "State updated twice")
//        let cancellable = change?.didSet(\.formattedDiff, perform: { newValue in
//          if newValue != nil {
//              if exp1.isFulfilled {
//                  exp2.fulfill()
//              } else {
//                  exp1.fulfill()
//              }
//          }
//        })
//        // Wait for the content to be initialized
//        try await fulfillment(of: exp1)
//
//      change?.handleReapplyChange()
//        try await fulfillment(of: exp2)
//      #expect(change?.targetContent == "Hi\nWorld")
//      #expect(change?.baseLineContent == "Hello\nWorld")
//      #expect(change?.canBeApplied == true)
//      #expect(change?.formattedDiff?.changes.map(\.change).targetContent == "Hi\nWorld")
//        _ = cancellable
//    }
//  }

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

  //     let change = await FileDiffViewModel(
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

  @MainActor
  @Test("Handles streaming input correctly")
  func test_streamingInput() async throws {
    let change = withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "line1\nline2\nline3"])
    } operation: {
      FileDiffViewModel(
        filePath: filePath.path(),
        changes: [FileDiff.SearchReplace(search: "line1", replace: "")])
    }

    let initialChange = try #require(change)
    try await waitForInitialization(of: initialChange)

    #expect(await initialChange.targetContent == "line2\nline3")

    let streamingUpdateExpectation = expectation(description: "Streaming update processed")
    let cancellable = initialChange.didSet(\.formattedDiff, perform: { _ in
      streamingUpdateExpectation.fulfillAtMostOnce()
    })

    // Simulate streaming input with additional changes
    initialChange.handle(newChanges: [
      FileDiff.SearchReplace(search: "line1", replace: "modified1"),
      FileDiff.SearchReplace(search: "line2", replace: "modified2"),
    ])

    try await fulfillment(of: streamingUpdateExpectation)
    let finalContent = await initialChange.targetContent
    #expect(finalContent == "modified1\nmodified2\nline3")
    _ = cancellable
  }

  @MainActor
  @Test("Processes multiple streaming updates")
  func test_multipleStreamingUpdates() async throws {
    let change = withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld\nTest"])
    } operation: {
      FileDiffViewModel(
        filePath: filePath.path(),
        changes: [FileDiff.SearchReplace(search: "Hello", replace: "Hi")])
    }

    let initialChange = try #require(change)
    try await waitForInitialization(of: initialChange)

    #expect(await initialChange.targetContent == "Hi\nWorld\nTest")

    let firstUpdateExpectation = expectation(description: "First streaming update")
    let secondUpdateExpectation = expectation(description: "Second streaming update")

    let updateCount = Atomic(0)
    let cancellable = initialChange.didSet(\.formattedDiff, perform: { _ in
      let count = updateCount.mutate { $0 += 1
        return $0
      }
      if count == 1 {
        firstUpdateExpectation.fulfill()
      } else if count == 2 {
        secondUpdateExpectation.fulfill()
      }
    })

    // First streaming update
    initialChange.handle(newChanges: [
      FileDiff.SearchReplace(search: "Hello", replace: "Hiii!"),
      FileDiff.SearchReplace(search: "World", replace: "Universe"),
    ])

    try await fulfillment(of: firstUpdateExpectation)
    let firstContent = await initialChange.targetContent
    #expect(firstContent == "Hiii!\nUniverse\nTest")

    // Second streaming update
    initialChange.handle(newChanges: [
      FileDiff.SearchReplace(search: "Hello", replace: "Hiii!"),
      FileDiff.SearchReplace(search: "World", replace: "Universe"),
      FileDiff.SearchReplace(search: "Test", replace: "Example"),
    ])

    try await fulfillment(of: secondUpdateExpectation)
    let secondContent = await initialChange.targetContent
    #expect(secondContent == "Hiii!\nUniverse\nExample")
    _ = cancellable
  }

  @MainActor
  @Test("Handles concurrent streaming updates safely")
  func test_concurrentStreamingUpdates() async throws {
    let change = withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "A\nB\nC\nD"])
    } operation: {
      FileDiffViewModel(
        filePath: filePath.path(),
        changes: [FileDiff.SearchReplace(search: "A", replace: "A1")])
    }

    let initialChange = try #require(change)
    try await waitForInitialization(of: initialChange)

    let updateExpectation = expectation(description: "Concurrent updates processed")

    let cancellable = initialChange.didSet(\.formattedDiff, perform: { _ in
      updateExpectation.fulfillAtMostOnce()
    })

    // Simulate concurrent streaming updates on main actor
    Task { @MainActor in
      initialChange.handle(newChanges: [
        FileDiff.SearchReplace(search: "B", replace: "B1"),
      ])
    }

    Task { @MainActor in
      initialChange.handle(newChanges: [
        FileDiff.SearchReplace(search: "C", replace: "C1"),
      ])
    }

    Task { @MainActor in
      initialChange.handle(newChanges: [
        FileDiff.SearchReplace(search: "D", replace: "D1"),
      ])
    }

    try await fulfillment(of: updateExpectation)

    // Verify that the latest replacement is applied
    let finalContent = await initialChange.targetContent
    #expect(finalContent == "A\nB\nC\nD1")
    _ = cancellable
  }

  @MainActor
  private func waitForInitialization(of change: FileDiffViewModel?) async throws {
    if change?.formattedDiff != nil {
      return
    }
    _ = await change?.targetContent
  }
}
