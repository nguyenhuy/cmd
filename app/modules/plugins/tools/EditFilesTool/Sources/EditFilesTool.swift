// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Dependencies
import FileDiffFoundation
import Foundation
import FoundationInterfaces
import JSONFoundation
import ToolFoundation
import XcodeControllerServiceInterface
import XcodeObserverServiceInterface

// MARK: - EditFilesTool

public final class EditFilesTool: Tool {
    
    
  public init() { }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
    public final class EditFilesToolUse: NonStreamableToolUse, @unchecked Sendable {

    init(callingTool: EditFilesTool, toolUseId: String, input: Input, context: ToolExecutionContext) {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.input = Input(files: input.files.map { fileChange in
        .init(
          path: fileChange.path.resolvePath(from: context.projectRoot).path(),
          isNewFile: fileChange.isNewFile,
          changes: fileChange.changes)
      })

      let (stream, updateStatus) = Status.makeStream(initial: .notStarted)
      status = stream
      self.updateStatus = updateStatus
    }

    public struct Input: Codable, Sendable {
      public let files: [FileChange]
      public struct FileChange: Codable, Sendable {
        public let path: String
        public let isNewFile: Bool?
        public let changes: [Change]
        public struct Change: Codable, Sendable {
          public let search: String
          public let replace: String
        }
      }
    }

    public struct Output: Codable, Sendable {
      public let result: JSON
    }

    public let isReadonly = false

    public let callingTool: EditFilesTool
    public let toolUseId: String
    public let input: Input

    public let status: Status

    public func startExecuting() {
      updateStatus.yield(.running)

      Task { @MainActor in
        var results: [String: JSON.Value] = [:]

        for fileChange in input.files {
          do {
            let filePath = URL(filePath: fileChange.path)

            // Try to get the content from the editor over the content from disk if possible.
            // TODO: look into doing this update _after_ the file has been made visible in Xcode.
            let editorContent = xcodeObserver.state.wrapped?.xcodesState.compactMap { xc in
              xc.workspaces.compactMap { ws in
                ws.tabs.compactMap { tab in
                  tab.knownPath == filePath ? tab.lastKnownContent : nil
                }.first
              }.first
            }.first
            let currentContent = try editorContent ?? fileManager.read(contentsOf: filePath, encoding: .utf8)
            let targetContent = try FileDiff.apply(
              searchReplace: fileChange.changes.map { .init(search: $0.search, replace: $0.replace) },
              to: currentContent)

            let fileDiff = try FileDiff.getFileChange(changing: currentContent, to: targetContent)
            try await xcodeController.apply(fileChange: FileChange(
              filePath: filePath,
              oldContent: currentContent,
              suggestedNewContent: fileDiff.newContent,
              selectedChange: fileDiff.diff))
            results[fileChange.path] = "All changes applied."
          } catch {
            results[fileChange.path] = .string("Error applying changes: \(error.localizedDescription)")
          }
        }
        updateStatus.yield(.completed(.success(.init(result: .object(results)))))
      }
    }

    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation

    @Dependency(\.xcodeController) private var xcodeController
    @Dependency(\.fileManager) private var fileManager
    @Dependency(\.xcodeObserver) private var xcodeObserver
  }

  public let name = "edit_or_create_files"

  public let description = """
    Request to replace existing code using search and replace blocks in a list of files.
    This tool allows for precise, surgical replaces to files by specifying exactly what content to search for and what to replace it with.
    The tool will maintain proper indentation and formatting while making changes.

    The SEARCH section must exactly match existing content including whitespace and indentation.
    If you're not confident in the exact content to search for, use the read_file tool first to get the exact content.
    When applying the diffs, be extra careful to remember to change any closing brackets or other syntax that may be affected by the diff farther down in the file.
    ALWAYS make as many changes in a single 'apply_diff' request as possible using multiple SEARCH/REPLACE blocks.
    ALWAYS try to minimize duplicate content in search/replace block and use several blocks instead when possible.

    example:

    Good example:
    - uses relative paths.
    - updates several files at once.
    - break down changes in one file into several blocks when possible.
    ```
    {
        "files": [
            {
                "path": "./Sources/MyFile.swift",
                "changes": [
                    {
                        "search": "import Foundation",
                        "replace": "import Foundation\nimport UIKit"
                    },
                    {
                        "search": "func add(a: Int, b: Int) -> Int",
                        "replace": "// Add two numbers\nfunc add(a: Int, b: Int) -> Int"
                    }
                ]
            },
            {
                "path": "./Tests/MyFileTests.swift",
                "changes": [
                    {
                        "search": "import XCTest",
                        "replace": "import Testing"
                    }
                ]
            }
        ]
    ```
    """

  public let inputSchema: JSON =
    try! JSONDecoder().decode(JSON.self, from: """
      {
        "type": "object",
        "properties": {
          "files": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "path": {
                  "type": "string",
                  "description": "The path of the file to modify. It should be relative to the project root."
                },
                "isNewFile": {
                  "type": "boolean",
                  "description": "Whether a new file should be created. In this case, and only in this case `search` should be an empty string."
                },
                "changes": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "search": {
                        "type": "string",
                        "description": "The text to search for in the file"
                      },
                      "replace": {
                        "type": "string",
                        "description": "The text to replace the search text with"
                      }
                    },
                    "required": ["search", "replace"]
                  }
                }
              },
              "required": ["path", "changes"]
            }
          }
        },
        "required": ["files"]
      }
      """.data(using: .utf8)!)

  public func isAvailable(in mode: ChatMode) -> Bool {
    mode == .agent
  }

  public func use(toolUseId: String, input: EditFilesToolUse.Input, context: ToolExecutionContext) -> EditFilesToolUse {
    EditFilesToolUse(callingTool: self, toolUseId: toolUseId, input: input, context: context)
  }
}

// MARK: - ToolUseViewModel
//
// @Observable
// @MainActor
// final class ToolUseViewModel {
//
//  init(
//    status: EditFilesTool.AskFollowUpToolUse.Status,
//    input: EditFilesTool.AskFollowUpToolUse.Input,
//    selectFollowUp: @escaping (String) -> Void)
//  {
//    self.status = status.value
//    self.input = input
//    self.selectFollowUp = selectFollowUp
//    Task {
//      for await status in status {
//        self.status = status
//      }
//    }
//  }
//
//  let input: EditFilesTool.AskFollowUpToolUse.Input
//  var status: ToolUseExecutionStatus<AskFollowUpTool.Output>
//  let selectFollowUp: (String) -> Void
// }
