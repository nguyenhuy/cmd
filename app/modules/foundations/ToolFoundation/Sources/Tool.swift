// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
// Export ChatFoundation as the protocol definition depends on types from it.
@_exported import ChatFoundation
import Combine
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import SwiftUI

// MARK: - Tool

/// A tool that can be called by the assistant.
public protocol Tool: Sendable {
  associatedtype SomeToolUse: ToolUse
  /// Use the tool with the given input. This doesn't start the execution, which happens when `startExecuting` is called on the tool use.
  func use(toolUseId: String, input: SomeToolUse.Input, context: ToolExecutionContext) -> SomeToolUse
  /// The name of the tool, used to identify it. It should only contain alphanumeric characters.
  var name: String { get }
  /// A description of what the tool does. The description of its input parameters is better suited for the `inputSchema` property.
  var description: String { get }
  /// The schema of the input parameters of the tool.
  var inputSchema: JSON { get }
  /// Whether the tool is available in the given mode.
  func isAvailable(in mode: ChatMode) -> Bool
}

extension Tool {
  public typealias Input = SomeToolUse.Input
  public typealias Output = SomeToolUse.Output

  /// Decodes the input and create a tool use.
  public func use(toolUseId: String, input: JSON, context: ToolExecutionContext) throws -> SomeToolUse {
    let data = try JSONEncoder().encode(input)
    let input = try JSONDecoder().decode(SomeToolUse.Input.self, from: data)
    return use(toolUseId: toolUseId, input: input, context: context)
  }

}

// MARK: - ToolUse

/// A specific usage of a tool.
public protocol ToolUse: Sendable {
  associatedtype Input: Codable & Sendable
  associatedtype Output: Codable & Sendable
  associatedtype SomeTool: Tool where SomeTool.SomeToolUse == Self

  typealias Status = CurrentValueStream<ToolUseExecutionStatus<Output>>

  /// The unique identifier of the tool use.
  var toolUseId: String { get }
  /// The input of the tool use.
  var input: Input { get }
  /// Whether the tool use is readonly or not
  /// (tools that modify derived data are categorized as readonly. eg a build tool would be readonly).
  var isReadonly: Bool { get }
  /// The tool that is being used.
  var callingTool: SomeTool { get }
  /// The status of the execution of the tool use.
  var status: Status { get }
    /// Whether this tool use expect to receive the input as it is being streamed, or once it is received entirely.
    static var canInputBeStreamed: Bool { get }
    /// Update the input with the updated one.
    /// Note: the tool can expect this to be called only if `canInputBeStreamed` is true.
    func receive(inputUpdate: Input)
  /// Start the execution of the tool use. The execution should not start before this method is called.
    /// Note: the tool can expect this to be called after all the input has been received, and to not receive later calls to `receive(inputUpdate:)`.
  func startExecuting()
}

public protocol NonStreamableToolUse: ToolUse {}

extension NonStreamableToolUse {
    public func receive(inputUpdate: Input) {}
    public static var canInputBeStreamed: Bool { false }
}


// MARK: - DisplayableToolUse

public protocol DisplayableToolUse: ToolUse {
  associatedtype SomeView: View
  @MainActor
  var body: SomeView { get }
}

// MARK: - ToolExecutionContext

public struct ToolExecutionContext {
  /// The path to the root of the project.
  public let projectRoot: URL

  public init(projectRoot: URL) {
    self.projectRoot = projectRoot
  }
}

// MARK: - ToolUseExecutionStatus

public enum ToolUseExecutionStatus<Output: Codable & Sendable>: Sendable {
  case notStarted
  case running
  case completed(Result<Output, Error>)
}

extension ToolUse {
  public var toolName: String { callingTool.name }

  public var result: Output {
    get async throws {
//       TODO: check why the iterator doesn't work nor completes if the value has already been set.
        if case .completed(let result) = status.value {
        return try result.get()
      }
      for await value in status {
        if case .completed(let result) = value {
          return try result.get()
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
