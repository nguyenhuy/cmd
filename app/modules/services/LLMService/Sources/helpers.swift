// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import JSONFoundation
import LLMServiceInterface
import ServerServiceInterface
import ToolFoundation

extension AssistantMessageContent {
  var asText: MutableCurrentValueStream<TextContentMessage>? {
    if case .text(let message) = self {
      return message
    }
    return nil
  }

  var asToolUseRequest: ToolUseMessage? {
    if case .tool(let message) = self {
      return message
    }
    return nil
  }
}

extension AssistantMessage {
  var message: Schema.Message {
    get throws {
      try Schema.Message(role: .assistant, content: content.map { content in
        switch content {
        case .text(let text):
          return .textMessage(Schema.TextMessage(text: text.content))
        case .tool(let toolUse):
          let toolUse = toolUse.toolUse
          let request = try Schema.ToolUseRequest(name: toolUse.callingTool.name, anyInput: toolUse.input, id: toolUse.toolUseId)
          return .toolUseRequest(request)
        }
      })
    }
  }
}

extension Schema.ToolResultMessage {
  public init(request: Schema.ToolUseRequest, output: JSON.Value) {
    self.init(
      toolUseId: request.toolUseId,
      toolName: request.toolName,
      result: .toolResultSuccessMessage(.init(success: output)))
  }
}

extension Schema.ToolResultMessage.Result {
  static func success(_ output: JSON.Value) -> Self {
    .toolResultSuccessMessage(.init(success: output))
  }

  static func failure(_ error: JSON.Value) -> Self {
    .toolResultFailureMessage(.init(failure: error))
  }

  static func failure(_ error: Error) -> Self {
    .failure(error.localizedDescription)
  }

  static func failure(_ errorDescription: String) -> Self {
    .failure(["error": .string(errorDescription)])
  }
}
