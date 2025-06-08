// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Dependencies
import Foundation
import JSONFoundation
import ServerServiceInterface
import ToolFoundation

// MARK: - LSTool

public final class LSTool: NonStreamableTool {

  public init() { }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
  public final class Use: ToolUse, @unchecked Sendable {
    init(callingTool: LSTool, toolUseId: String, input: Input, context: ToolExecutionContext) {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.context = context
      self.input = Input(
        path: input.path.resolvePath(from: context.projectRoot).path(),
        recursive: input.recursive)
      directoryPath = URL(fileURLWithPath: self.input.path)

      let (stream, updateStatus) = Status.makeStream(initial: .pendingApproval)
      status = stream
      self.updateStatus = updateStatus
    }

    public struct Input: Codable, Sendable {
      public let path: String
      public let recursive: Bool?
    }

    public struct Output: Codable, Sendable {
      public let files: [File]
      /// Whether the output was truncated because there are too many files to reasonably return.
      public let hasMore: Bool
      public struct File: Codable, Sendable {
        /// The full path of the file
        public let path: String
        /// The attributes of the file, e.g. like `drwxr-xr-x`.
        public let attr: String
        /// The size of the file in human-readable format.
        public let size: String
      }
    }

    public let isReadonly = true

    public let callingTool: LSTool
    public let toolUseId: String
    public let input: Input

    public let status: Status

    public func startExecuting() {
      // Transition from pendingApproval to notStarted to running
      updateStatus.yield(.notStarted)
      updateStatus.yield(.running)

      guard let projectRoot = context.projectRoot else {
        updateStatus.yield(.completed(.failure(AppError("Cannot list files without a project"))))
        return
      }
      Task {
        do {
          let fullInput = Schema.ListFilesToolInput(
            projectRoot: projectRoot.path(),
            path: input.path,
            recursive: input.recursive)

          let data = try JSONEncoder().encode(fullInput)
          let response: Schema.ListFilesToolOutput = try await server.postRequest(path: "listFiles", data: data)
          updateStatus.yield(.completed(.success(response.transformed(with: context))))
        } catch {
          updateStatus.yield(.completed(.failure(error)))
        }
      }
    }

    public func reject(reason: String?) {
      updateStatus.yield(.rejected(reason: reason))
    }

    let directoryPath: URL

    @Dependency(\.server) private var server
    private let context: ToolExecutionContext

    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation

  }

  public let name = "list_files"

  public let description = """
    Request to list files and directories within the specified directory. If recursive is true, it will list all files and directories recursively. If recursive is false or not provided, it will only list the top-level contents.
    """

  public var displayName: String {
    "List Files"
  }

  public var shortDescription: String {
    "Lists files and directories within a specified directory, optionally recursive."
  }

  public var inputSchema: JSON {
    .object([
      "type": .string("object"),
      "properties": .object([
        "path": .object([
          "type": .string("string"),
          "description": .string("The directory path to list. If the absolute path is known it should be used. Otherwise use a relative path."),
        ]),
        "recursive": .object([
          "type": .string("boolean"),
          "description": .string("Whether to list files recursively in subdirectories. Default is false."),
        ]),
      ]),
      "required": .array([.string("path")]),
    ])
  }

  public func isAvailable(in _: ChatMode) -> Bool {
    true
  }

  public func use(toolUseId: String, input: Use.Input, context: ToolExecutionContext) -> Use {
    Use(callingTool: self, toolUseId: toolUseId, input: input, context: context)
  }

}

// MARK: - ToolUseViewModel

@Observable
@MainActor
final class ToolUseViewModel {

  init(status: LSTool.Use.Status, directoryPath: URL) {
    self.status = status.value
    self.directoryPath = directoryPath
    Task {
      for await status in status {
        self.status = status
      }
    }
  }

  let directoryPath: URL
  var status: ToolUseExecutionStatus<LSTool.Use.Output>
}

extension Schema.ListFilesToolOutput {
  func transformed(with context: ToolExecutionContext) -> LSTool.Use.Output {
    .init(
      files: files.map { file in
        .init(
          path: file.path.resolvePath(from: context.projectRoot).path(),
          attr: file.permissions,
          size: ByteCountFormatter.string(fromByteCount: Int64(file.byteSize), countStyle: .file))
      }, hasMore: files.contains(where: { $0.hasMoreContent == true }))
  }
}

extension LSTool.Use {
  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let callingTool = try container.decode(LSTool.self, forKey: .callingTool)
    let toolUseId = try container.decode(String.self, forKey: .toolUseId)
    let input = try container.decode(Input.self, forKey: .input)
    let context = try container.decode(ToolExecutionContext.self, forKey: .context)
    let statusValue = try container.decode(ToolUseExecutionStatus<Output>.self, forKey: .status)

    self.init(callingTool: callingTool, toolUseId: toolUseId, input: input, context: context)

    // Set the status to the decoded value
    updateStatus.yield(statusValue)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(callingTool, forKey: .callingTool)
    try container.encode(toolUseId, forKey: .toolUseId)
    try container.encode(input, forKey: .input)
    try container.encode(context, forKey: .context)
    try container.encode(status.value, forKey: .status)
  }

  private enum CodingKeys: String, CodingKey {
    case callingTool
    case toolUseId
    case input
    case context
    case status
  }
}
