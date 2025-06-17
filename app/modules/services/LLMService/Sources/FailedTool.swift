// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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

  func cancel() { }
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
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    toolUseId = try container.decode(String.self, forKey: .toolUseId)
    callingTool = try container.decode(FailedTool.self, forKey: .tool)
    errorDescription = try container.decode(String.self, forKey: .errorDescription)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(toolUseId, forKey: .toolUseId)
    try container.encode(callingTool, forKey: .tool)
    try container.encode(errorDescription, forKey: .errorDescription)
  }

  private enum CodingKeys: String, CodingKey {
    case toolUseId
    case tool
    case errorDescription
  }
}
