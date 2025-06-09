// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Dependencies
import Foundation
import JSONFoundation
import ToolFoundation
import XcodeControllerServiceInterface

// MARK: - BuildTool

public typealias BuildType = XcodeControllerServiceInterface.BuildType

// MARK: - BuildTool

public final class BuildTool: NonStreamableTool {
  public init() { }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
  public final class Use: ToolUse, @unchecked Sendable {

    init(
      callingTool: BuildTool,
      toolUseId: String,
      input: Input,
      context: ToolExecutionContext,
      initialStatus: Status.Element? = nil)
    {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.context = context
      self.input = input

      let (stream, updateStatus) = Status.makeStream(initial: initialStatus ?? .pendingApproval)
      status = stream
      self.updateStatus = updateStatus
    }

    public struct Input: Codable, Sendable {
      public let `for`: BuildType

      public init(`for`: BuildType) {
        self.for = `for`
      }
    }

    public struct Output: Codable, Sendable {
      let buildResult: BuildSection
      let isSuccess: Bool
    }

    /// True as building only modifies derived data.
    public let isReadonly = true

    public let callingTool: BuildTool
    public let toolUseId: String
    public let input: Input

    public let status: Status

    public func startExecuting() {
      // Transition from pendingApproval to notStarted to running
      updateStatus.yield(.notStarted)
      updateStatus.yield(.running)

      guard let project = context.project else {
        updateStatus.yield(.completed(.failure(AppError("No project selected to run build"))))
        return
      }

      Task {
        do {
          let buildType = input.for
          let buildResult = try await xcodeController.build(project: project, buildType: buildType)

          let isSuccess = buildResult.maxSeverity != .error
          updateStatus.yield(.completed(.success(Output(buildResult: buildResult, isSuccess: isSuccess))))
        } catch {
          updateStatus.yield(.completed(.failure(error)))
        }
      }
    }

    public func reject(reason: String?) {
      updateStatus.yield(.rejected(reason: reason))
    }

    let context: ToolExecutionContext

    @Dependency(\.xcodeController) private var xcodeController

    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation

  }

  public let name = "build"

  public let description = """
    Request to trigger a build action in Xcode. This tool allows you to build for testing or running and to get the output in case of failure.
    """

  public var displayName: String {
    "Build"
  }

  public var shortDescription: String {
    "Triggers Xcode build actions for testing or running and provides output results."
  }

  public var inputSchema: JSON {
    .object([
      "type": .string("object"),
      "properties": .object([
        "for": .object([
          "type": .string("string"),
          "description": .string("The build type to execute. Must be either 'test' or 'run'."),
          "enum": .array([
            .string("test"),
            .string("run"),
          ]),
        ]),
      ]),
      "required": .array([.string("for")]),
    ])
  }

  public func isAvailable(in chatMode: ChatMode) -> Bool {
    chatMode == .agent
  }

  public func use(toolUseId: String, input: Use.Input, context: ToolExecutionContext) -> Use {
    Use(callingTool: self, toolUseId: toolUseId, input: input, context: context)
  }
}

// MARK: - ToolUseViewModel

@Observable
@MainActor
final class ToolUseViewModel {

  init(
    buildType: BuildType,
    status: BuildTool.Use.Status)
  {
    self.buildType = buildType
    self.status = status.value
    Task {
      for await status in status {
        self.status = status
      }
    }
  }

  let buildType: BuildType
  var status: ToolUseExecutionStatus<BuildTool.Use.Output>
}

extension BuildMessage {
  var description: String {
    "\(severity.description): \(message)\((location?.description).map { " at \($0)" } ?? "")"
  }
}

extension BuildMessage.Severity {
  var description: String {
    switch self {
    case .info:
      "info"
    case .warning:
      "warning"
    case .error:
      "error"
    }
  }
}

extension BuildMessage.Location {
  var description: String {
    if let startingLineNumber, let startingColumnNumber, let endingLineNumber, let endingColumnNumber {
      "\(file.path()) Line \(startingLineNumber):\(startingColumnNumber) to Line \(endingLineNumber):\(endingColumnNumber)"
    } else {
      file.path()
    }
  }
}
