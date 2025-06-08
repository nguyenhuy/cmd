// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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

  /// Use the tool with the given input. This doesn't start the execution, which happens when `startExecuting` is called on the tool use.
  public func use(toolUseId: String, input: Data, isInputComplete _: Bool, context: ToolExecutionContext) throws -> Use {
//        let input = try JSONDecoder().decode(Input.self, from: input)
    try Use(toolUseId: toolUseId, input: input, callingTool: self as! Self.Use.SomeTool, context: context, status: nil)
  }

  /// Re-create the tool use from its serialization.
  public func deserialize(
    toolUseId: String,
    input: Data,
    context: ToolExecutionContext,
    status: ToolUseExecutionStatus<Data>)
    throws -> Use
  {
//        let input = try JSONDecoder().decode(Input.self, from: input)
    try Use(
      toolUseId: toolUseId,
      input: input,
      callingTool: self as! Self.Use.SomeTool,
      context: context,
      status: status.map { try JSONDecoder().decode(Output.self, from: $0) })
  }
}

// MARK: - ToolUse

/// A specific usage of a tool.
public protocol ToolUse: Sendable {
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
  /// The context in which the tool use is being executed.
  var context: ToolExecutionContext { get }
  /// Create a new instance of the tool use.
  init(toolUseId: String, input: Data, callingTool: SomeTool, context: ToolExecutionContext, status: Status.Element?) throws
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

  public init(toolUseId: String, input: Data, callingTool: SomeTool, context: ToolExecutionContext) throws {
    try self.init(toolUseId: toolUseId, input: input, callingTool: callingTool, context: context, status: nil)
  }

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

  public var currentStatus: ToolUseExecutionStatus<Output> {
    status.value
  }

}

/// A tool that doesn't support streamed input, and that needs to have all its input to start a tool use.
public protocol NonStreamableTool: Tool {
  /// Use the tool with the given input. This doesn't start the execution, which happens when `startExecuting` is called on the tool use.
//  func use(toolUseId: String, input: Use.Input, context: ToolExecutionContext) -> Use
}

extension NonStreamableTool {
  public var canInputBeStreamed: Bool { false }

//  public func use(toolUseId: String, input: Data, isInputComplete: Bool, context: ToolExecutionContext) throws -> Use {
//    assert(isInputComplete)
//    let input = try JSONDecoder().decode(Input.self, from: input)
//    return use(toolUseId: toolUseId, input: input, context: context)
//  }
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

extension ToolUseExecutionStatus {
  public var output: Output? {
    switch self {
    case .completed(let result):
      switch result {
      case .success(let output):
        output
      case .failure:
        nil
      }

    default:
      nil
    }
  }

  public func map<NewOutput: Codable & Sendable>(_ map: (Output) throws -> NewOutput) rethrows
    -> ToolUseExecutionStatus<NewOutput>
  {
    switch self {
    case .pendingApproval:
      .pendingApproval
    case .rejected(let reason):
      .rejected(reason: reason)
    case .notStarted:
      .notStarted
    case .running:
      .running
    case .completed(let result):
      switch result {
      case .failure(let error):
        .completed(.failure(error))
      case .success(let output):
        try .completed(.success(map(output)))
      }
    }
  }

}

public enum StreamableInput<StreamingInput: Codable & Sendable, StreamedInput: Codable & Sendable>: Codable, Sendable {
  case streaming(_ input: StreamingInput)
  case streamed(_ input: StreamedInput)

  public init(from decoder: any Decoder) throws {
    /// When working with streamed input,
    self = try .streaming(StreamingInput(from: decoder))
  }

  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .streaming(let input):
      try input.encode(to: encoder)
    case .streamed(let input):
      try input.encode(to: encoder)
    }
  }
}

extension KeyedDecodingContainer {
  /// Decodes an array, dropping values that failed to decode.
  /// This can be useful to decode streamed input, where the last value in the array was truncated in a way that makes decoding impossible.
  public func resilientlyDecode<T: Decodable>(_: [T].Type, forKey key: K) throws -> [T] {
    var items = [T?]()
    var container = try nestedUnkeyedContainer(forKey: key)
    while !container.isAtEnd, items.count < container.count ?? Int.max {
      items.append(try? container.decode(T.self))
    }
    return items.compactMap(\.self)
  }
}
