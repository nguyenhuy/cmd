// Copyright Xcompanion. All rights reserved.
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
    withDependencies {
      $0.fileManager = MockFileManager(files: [filePath.path(): "Hello\nWorld"])
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

      #expect(change != nil)
      #expect(change?.baseLineContent == "Hello\nWorld")
      #expect(change?.targetContent == "Hi\nWorld")
      #expect(change?.canBeApplied == true)
    }
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
    try await withDependencies {
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

      let change = try #require(suggestedChange)
      #expect(change.targetContent == "Hi\nWorld")
      let formattedDiff = try #require(change.formattedDiff)

      try change.handleReject(changes: formattedDiff.changes)
      #expect(change.targetContent == "Hello\nWorld")
      #expect(change.formattedDiff?.changes.map(\.change).targetContent == "Hello\nWorld")
    }
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
  private func waitForInitialization(of change: FileDiffViewModel?) async throws {
    if change?.formattedDiff != nil {
      return
    }
    let exp = expectation(description: "State updated")

    let cancellable = change?.didSet(\.formattedDiff, perform: { newValue in
      if newValue != nil {
        exp.fulfillAtMostOnce()
      }
    })
    try await fulfillment(of: exp)
    _ = cancellable
  }
}
