// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import FileDiffFoundation
import Foundation
import FoundationInterfaces
import JSONFoundation
import ThreadSafe
import ToolFoundation

// MARK: - EditFilesTool

public final class EditFilesTool: Tool {

  public init(shouldAutoApply: Bool) {
    self.shouldAutoApply = shouldAutoApply
  }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
  public final class Use: ToolUse, @unchecked Sendable {

    init(
      callingTool: EditFilesTool,
      toolUseId: String,
      input: Data,
      isInputComplete: Bool,
      context: ToolExecutionContext)
      throws
    {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.isInputComplete = Atomic(isInputComplete)
      self.context = context
      let input = try JSONDecoder().decode(Input.self, from: input).withPathsResolved(from: context.projectRoot)
      _input = Atomic(input)

      let (stream, updateStatus) = Status.makeStream(initial: .pendingApproval)
      status = stream
      self.updateStatus = updateStatus
    }

    public struct Input: Codable, Sendable {
      init(files: [FileChange]) {
        self.files = files
      }

      public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: String.self)
        // Decode all the values possible, and drop those that are still missing required properties to be decoded.
        files = try container.resilientlyDecode([FileChange].self, forKey: "files")
      }

      public struct FileChange: Codable, Sendable {
        public struct Change: Codable, Sendable {
          public let search: String
          public let replace: String

          public init(search: String, replace: String) {
            self.search = search
            self.replace = replace
          }

          public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: String.self)
            // Decode with default values, since when streaming not all keys may be present.
            search = (try? container.decode(String.self, forKey: "search")) ?? ""
            replace = (try? container.decode(String.self, forKey: "replace")) ?? ""
          }
        }

        public let path: String
        public let isNewFile: Bool?
        public let changes: [Change]

      }

      public let files: [FileChange]

      func withPathsResolved(from root: URL?) -> Input {
        Input(files: files.map { fileChange in
          FileChange(
            path: fileChange.path.resolvePath(from: root).path(),
            isNewFile: fileChange.isNewFile,
            changes: fileChange.changes)
        })
      }
    }

    public struct Output: Codable, Sendable {
      public let result: JSON
    }

    public let isReadonly = false

    public let callingTool: EditFilesTool
    public let toolUseId: String
    public let _input: Atomic<Input>
    public let status: Status

    public var input: Input { _input.value }

    public func receive(inputUpdate data: Data, isLast: Bool) throws {
      let input = try JSONDecoder().decode(Input.self, from: data).withPathsResolved(from: context.projectRoot)
      _input.set(to: input)
      isInputComplete.set(to: isLast)

      Task { @MainActor [weak self] in
        self?._viewModel?.input = input
        self?._viewModel?.isInputComplete = isLast
      }
    }

    public func startExecuting() {
      // Transition from pendingApproval to notStarted to running
      updateStatus.yield(.notStarted)
      updateStatus.yield(.running)
      guard isInputComplete.value else {
        updateStatus.yield(.completed(.failure(AppError("Started executing before the input was entirely received"))))
        return
      }

      if callingTool.shouldAutoApply {
        Task { @MainActor in
          await viewModel.applyAllChanges()
        }
      } else {
        Task { @MainActor in
          viewModel.acknowledgeSuggestionReceived()
        }
      }
    }

    public func reject(reason: String?) {
      updateStatus.yield(.rejected(reason: reason))
    }

    let isInputComplete: Atomic<Bool>

    @MainActor
    var viewModel: ToolUseViewModel {
      if let _viewModel {
        return _viewModel
      }
      let viewModel = ToolUseViewModel(
        status: status,
        input: input,
        isInputComplete: isInputComplete.value,
        updateToolStatus: { [weak self] newStatus in
          self?.updateStatus.yield(newStatus)
        })
      _viewModel = viewModel
      return viewModel
    }

    @MainActor private var _viewModel: ToolUseViewModel?

    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation
    private let context: ToolExecutionContext

  }

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
      """.utf8Data)

  public let canInputBeStreamed = true

  public var name: String {
    if shouldAutoApply {
      "edit_or_create_files"
    } else {
      "suggest_files_changes"
    }
  }

  public var displayName: String {
    "Edit Files"
  }

  public var description: String { """
    \(shortDescription)
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
  }

  public var shortDescription: String {
    if shouldAutoApply {
      "Replace existing code using search/replace blocks in a list of files and create new files."
    } else {
      "Suggest to replace existing code using search/replace blocks in a list of files and to create new files."
    }
  }

  public func isAvailable(in mode: ChatMode) -> Bool {
    switch mode {
    case .agent:
      shouldAutoApply
    case .ask:
      !shouldAutoApply
    }
  }

  public func use(
    toolUseId: String,
    input: Data,
    isInputComplete: Bool,
    context: ToolExecutionContext)
    throws -> Use
  {
    try Use(
      callingTool: self,
      toolUseId: toolUseId,
      input: input,
      isInputComplete: isInputComplete,
      context: context)
  }

  private let shouldAutoApply: Bool

}

extension EditFilesTool.Use {
  public convenience init(from _: Decoder) throws {
    fatalError("not implemented")
  }

  public func encode(to _: Encoder) throws {
    fatalError("not implemented")
  }
}
