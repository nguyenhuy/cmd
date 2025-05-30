// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import JSONFoundation
import ToolFoundation

// MARK: - EmptyObject

struct EmptyObject: Codable, Sendable { }

// MARK: - FailedToolUse

struct FailedToolUse: ToolUse {

  init(toolUseId: String, toolName: String, error: Error) {
    self.toolUseId = toolUseId
    callingTool = FailedTool(name: toolName)
    self.error = error
  }

  public let isReadonly = true

  typealias Input = EmptyObject
  typealias Output = EmptyObject

  var callingTool: FailedTool
  let toolUseId: String
  let error: Error

  var status: CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<EmptyObject>> { .Just(.completed(.failure(error))) }

  var input: Input { Input() }

  func startExecuting() { }
}

// MARK: - FailedTool

struct FailedTool: NonStreamableTool {
  typealias Use = FailedToolUse

  func isAvailable(in _: ChatMode) -> Bool {
    true
  }

  init(name: String) {
    self.name = name
  }

  func use(toolUseId _: String, input _: EmptyObject, context _: ToolExecutionContext) -> FailedToolUse {
    fatalError("Should not be called")
  }

  let name: String
  var description: String { "Failed tool" }
  var inputSchema: JSON { .object([:]) }
}
