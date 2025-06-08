// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import ToolFoundation

// MARK: - ToolUseError

struct ToolUseError: Error, Codable, Sendable {
  let toolName: String
  let message: String
}

// MARK: - EmptyObject

struct EmptyObject: Codable, Sendable { }

// MARK: - FailedToolUse

struct FailedToolUse: ToolUse {
  init(
    toolUseId: String,
    input: Data,
    callingTool _: FailedTool,
    context: ToolExecutionContext,
    status _: Status.Element?)
    throws
  {
    self.toolUseId = toolUseId
    self.context = context
    let input = try JSONDecoder().decode(ToolUseError.self, from: input)
    callingTool = FailedTool(name: input.toolName)
    self.input = input
    error = AppError(input.message)
  }

  init(toolUseId: String, toolName: String, error: Error, context: ToolExecutionContext) {
    self.toolUseId = toolUseId
    callingTool = FailedTool(name: toolName)
    self.error = error
    input = .init(toolName: toolName, message: error.localizedDescription)
    self.context = context
  }

  public let isReadonly = true

  typealias Input = ToolUseError
  typealias Output = EmptyObject

  let context: ToolExecutionContext

  var callingTool: FailedTool
  let toolUseId: String
  let error: Error

  let input: Input

  var status: CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<EmptyObject>> { .Just(.completed(.failure(error))) }

  func startExecuting() { }

  func reject(reason _: String?) { }
}

// MARK: - FailedTool

struct FailedTool: NonStreamableTool {
  init(name: String) {
    self.name = name
  }

  typealias Use = FailedToolUse

  let name: String

  var displayName: String {
    "Failed tool"
  }

  var description: String { "Failed tool" }
  var inputSchema: JSON { .object([:]) }

  func isAvailable(in _: ChatMode) -> Bool {
    true
  }

  func use(toolUseId _: String, input _: EmptyObject, context _: ToolExecutionContext) -> FailedToolUse {
    fatalError("Should not be called")
  }

}
