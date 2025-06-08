// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import JSONFoundation
import ToolFoundation

// MARK: - EmptyObject

struct EmptyObject: Codable, Sendable { }

// MARK: - FailedToolUse

struct FailedToolUse: ToolUse {

  init(toolUseId: String, toolName: String, errorDescription: String) {
    self.toolUseId = toolUseId
    callingTool = FailedTool(name: toolName)
    self.errorDescription = errorDescription
  }

  public let isReadonly = true

  typealias Input = EmptyObject
  typealias Output = EmptyObject

  var callingTool: FailedTool
  let toolUseId: String
  let errorDescription: String

  var status: CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<EmptyObject>> {
    .Just(.completed(.failure(AppError(errorDescription))))
  }

  var input: Input { Input() }

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

  var shortDescription: String {
    "Placeholder for tools that failed to execute properly."
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

extension FailedToolUse {
  public init(from _: Decoder) throws {
    fatalError("not implemented")
  }

  public func encode(to _: Encoder) throws {
    fatalError("not implemented")
  }
}
