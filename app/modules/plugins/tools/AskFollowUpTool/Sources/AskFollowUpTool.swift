// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Dependencies
import Foundation
import JSONFoundation
import ToolFoundation

// MARK: - AskFollowUpTool

public final class AskFollowUpTool: NonStreamableTool {

  public init() { }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
  public final class Use: ToolUse, @unchecked Sendable {
    init(callingTool: AskFollowUpTool, toolUseId: String, input: Input) {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.input = input

      let (stream, updateStatus) = Status.makeStream(initial: .notStarted)
      status = stream
      self.updateStatus = updateStatus
    }

    public struct Input: Codable, Sendable {
      public let question: String
      public let followUp: [String]
    }

    public struct Output: Codable, Sendable {
      public let response: String
    }

    public let isReadonly = true

    public let callingTool: AskFollowUpTool
    public let toolUseId: String
    public let input: Input

    public let status: Status

    public func startExecuting() {
      updateStatus.yield(.running)
    }

    func select(followUp: String) {
      updateStatus.yield(.completed(.success(.init(response: followUp))))
    }

    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation

  }

  public let name = "ask_followup"
  
  public var displayName: String {
    "Follow Up Tool"
  }

  public let description = """
    Ask the user a question to gather additional information needed to complete the task. This tool should be used when you encounter ambiguities, need clarification, or require more details to proceed effectively. It allows for interactive problem-solving by enabling direct communication with the user. Use this tool judiciously to maintain a balance between gathering necessary information and avoiding excessive back-and-forth.
    """

  public var inputSchema: JSON {
    .object([
      "type": .string("object"),
      "properties": .object([
        "question": .object([
          "type": .string("string"),
          "description": .string("The directory path to list. If the absolute path is known it should be used. Otherwise use a relative path."),
        ]),
        "followUp": .object([
          "type": .string("array"),
          "items": .object([
            "type": .string("string"),
          ]),
          "description": .string("""
            A list of 2-4 suggested answers that logically follow from the question, ordered by priority or logical sequence. Each suggestion must:
              1. Be specific, actionable, and directly related to the completed task
              2. Be a complete answer to the question - the user should not need to provide additional information or fill in any missing details. DO NOT include placeholders with brackets or parentheses.
            """),
        ]),
      ]),
      "required": .array([.string("question"), .string("followUp")]),
    ])
  }

  public func isAvailable(in _: ChatMode) -> Bool {
    true
  }

  public func use(toolUseId: String, input: Use.Input, context _: ToolExecutionContext) -> Use {
    Use(callingTool: self, toolUseId: toolUseId, input: input)
  }
}

// MARK: - ToolUseViewModel

@Observable
@MainActor
final class ToolUseViewModel {

  init(
    status: AskFollowUpTool.Use.Status,
    input: AskFollowUpTool.Use.Input,
    selectFollowUp: @escaping (String) -> Void)
  {
    self.status = status.value
    self.input = input
    self.selectFollowUp = selectFollowUp
    Task {
      for await status in status {
        self.status = status
      }
    }
  }

  let input: AskFollowUpTool.Use.Input
  var status: ToolUseExecutionStatus<AskFollowUpTool.Output>
  let selectFollowUp: (String) -> Void
}
