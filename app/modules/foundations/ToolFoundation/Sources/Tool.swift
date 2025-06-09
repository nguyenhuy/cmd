// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppFoundation
// Re-export ChatFoundation as the protocols defined here depend on types from this module.
@_exported import ChatFoundation
import Combine
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import SwiftUI

// MARK: - Tool

/// A tool that can be called by the assistant and execute tasks locally.
/// Each invocation of the tool is a 'tool use' that has its own input/output/state and possibly UI.
public protocol Tool: Sendable {
  associatedtype Use: ToolUse
  /// Use the tool with the given input. This doesn't start the execution, which happens when `startExecuting` is called on the tool use.
  func use(toolUseId: String, input: Data, isInputComplete: Bool, context: ToolExecutionContext) throws -> Use
  /// The name of the tool, used to identify it. It should only contain alphanumeric characters.
  var name: String { get }
  /// A description of what the tool does. The description of its input parameters is better suited for the `inputSchema` property.
  var description: String { get }
  /// The schema of the input parameters of the tool.
  var inputSchema: JSON { get }
  /// Whether the tool is available in the given chat mode.
  func isAvailable(in mode: ChatMode) -> Bool
  /// Whether this tool expect to receive the input as it is being streamed, or only once it is received entirely.
  var canInputBeStreamed: Bool { get }
  /// The tool display name
  var displayName: String { get }
  /// A short description of the tool (max 3 lines)
  var shortDescription: String { get }
}

extension Tool {
  public typealias Input = Use.Input
  public typealias Output = Use.Output

}

// MARK: - ToolUse

/// A specific usage of a tool.
public protocol ToolUse: Sendable, Codable {
  associatedtype Input: Codable & Sendable
  associatedtype Output: Codable & Sendable
  associatedtype SomeTool: Tool where SomeTool.Use == Self

  typealias Status = CurrentValueStream<ToolUseExecutionStatus<Output>>

  /// The unique identifier of the tool use.
  var toolUseId: String { get }
  /// The input of the tool use.
  var input: Input { get }
  /// Whether the tool use is readonly or not.
  /// (tools that modify derived data are categorized as readonly. eg a build tool would be readonly).
  var isReadonly: Bool { get }
  /// The tool that is being used.
  var callingTool: SomeTool { get }
  /// The status of the execution of the tool use.
  var status: Status { get }
  /// Update the input with the updated one.
  /// Note: the tool can expect this to be called only if `canInputBeStreamed` is true.
  /// - Parameters:
  ///   - inputUpdate: The update input containing all the data since it started streaming.
  ///   - isLast: Whether this is the last chunk of the input.
  func receive(inputUpdate: Data, isLast: Bool) throws
  /// Start the execution of the tool use. The execution should not start before this method is called.
  /// Note: the tool can expect this to be called after all the input has been received, and to not receive later calls to `receive(inputUpdate:)`.
  func startExecuting()
  /// Reject the tool use with an optional reason.
  func reject(reason: String?)
}

extension ToolUse {

  public var toolName: String { callingTool.name }

  public var toolDisplayName: String { callingTool.displayName }

  public var result: Output {
    get async throws {
      //       TODO: check why the iterator doesn't work nor completes if the value has already been set.
      if case .completed(let result) = status.value {
        return try result.get()
      }
      if case .rejected(let reason) = status.value {
        throw AppError(message: reason ?? "Tool use was rejected")
      }
      for await value in status {
        if case .completed(let result) = value {
          return try result.get()
        }
        if case .rejected(let reason) = value {
          throw AppError(message: reason ?? "Tool use was rejected")
        }
      }
      throw AppError(message: "The tool use completed with no result.")
    }
  }

  public var currentResult: Output? {
    guard case .completed(let result) = status.value else { return nil }
    return try? result.get()
  }

}

/// A tool that doesn't support streamed input, and that needs to have all its input to start a tool use.
public protocol NonStreamableTool: Tool {
  /// Use the tool with the given input. This doesn't start the execution, which happens when `startExecuting` is called on the tool use.
  func use(toolUseId: String, input: Use.Input, context: ToolExecutionContext) -> Use
}

extension NonStreamableTool {
  public var canInputBeStreamed: Bool { false }

  public func use(toolUseId: String, input: Data, isInputComplete: Bool, context: ToolExecutionContext) throws -> Use {
    assert(isInputComplete)
    let input = try JSONDecoder().decode(Input.self, from: input)
    return use(toolUseId: toolUseId, input: input, context: context)
  }
}

extension ToolUse where SomeTool: NonStreamableTool {
  public func receive(inputUpdate _: Data, isLast _: Bool) throws { }
}

// MARK: - DisplayableToolUse

/// A tool that can be displayed in th UI.
public protocol DisplayableToolUse: ToolUse {
  associatedtype SomeView: View
  @MainActor
  var body: SomeView { get }
}

// MARK: - ToolExecutionContext

/// The context in which a tool use has been created.
public struct ToolExecutionContext: Sendable, Codable {
  /// The path to the project.
  public let project: URL?
  /// The path to the root of the project.
  /// For a Swift package this is the same as the project. For an xcodeproj this is the containing directory.
  public let projectRoot: URL?

  public init(project: URL?, projectRoot: URL?) {
    self.project = project
    self.projectRoot = projectRoot
  }
}

// MARK: - ToolUseExecutionStatus

public enum ToolUseExecutionStatus<Output: Codable & Sendable>: Sendable {
  case pendingApproval
  case rejected(reason: String?)
  case notStarted
  case running
  case completed(Result<Output, Error>)

}

public enum StreamableInput<StreamingInput: Codable & Sendable, StreamedInput: Codable & Sendable>: Sendable {
  case streaming(_ input: StreamingInput)
  case streamed(_ input: StreamedInput)
}
