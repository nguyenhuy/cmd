// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import JSONFoundation
import LLMServiceInterface
import ServerServiceInterface
import SettingsServiceInterface
import ToolFoundation
@testable import LLMService

extension DefaultLLMService {

  convenience init(
    server: MockServer = MockServer(),
    settingsService: MockSettingsService = MockSettingsService(.init(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(
        apiKey: "anthropic-key",
        apiUrl: nil),
      openAISettings: .init(apiKey: "openai-key", apiUrl: nil))))
  {
    self.init(server: server as Server, settingsService: settingsService as SettingsService)
  }

  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any Tool] = [])
    async throws -> UpdateStream
  {
    try await withCheckedThrowingContinuation { continuation in
      Task {
        _ = try await sendMessage(
          messageHistory: messageHistory,
          tools: tools,
          model: .claudeSonnet,
          context: TestChatContext(projectRoot: URL(filePath: "/path/to/root")))
        { stream in continuation
          .resume(returning: stream)
        }
      }
    }
  }

  func sendOneMessage(
    messageHistory: [Schema.Message],
    tools: [any Tool] = [])
    async throws -> CurrentValueStream<AssistantMessage>
  {
    try await withCheckedThrowingContinuation { continuation in
      Task {
        _ = try await sendOneMessage(
          messageHistory: messageHistory,
          tools: tools,
          model: .claudeSonnet,
          context: TestChatContext(projectRoot: URL(filePath: "/path/to/root")))
        { stream in continuation
          .resume(returning: stream)
        }
      }
    }
  }
}

// MARK: - TestToolUse

struct TestToolUse<Input: Codable & Sendable, Output: Codable & Sendable>: ToolUse {

  init(callingTool: TestTool<Input, Output>, toolUseId: String, input: Input, output: Result<Output, Error>, isReadonly: Bool) {
    self.toolUseId = toolUseId
    self.callingTool = callingTool
    self.input = input
    self.output = output
    self.isReadonly = isReadonly
    status = .Just(.completed(output))
  }

  var callingTool: TestTool<Input, Output>
  let toolUseId: String
  let isReadonly: Bool
  let input: Input
  let output: Result<Output, Error>

  let status: CurrentValueStream<ToolFoundation.ToolUseExecutionStatus<Output>>

  func startExecuting() { }
}

// MARK: - TestTool

struct TestTool<Input: Codable & Sendable, Output: Codable & Sendable>: Tool {
  init(
    name: String = "TestTool",
    output: Result<Output, Error>,
    isReadonly: Bool = true,
    isAvailableInChatMode: @escaping @Sendable (ChatMode) -> Bool = { _ in true })
  {
    self.name = name
    self.isReadonly = isReadonly
    self.output = output
    self.isAvailableInChatMode = isAvailableInChatMode
  }

  init(name: String = "TestTool", output: Output) {
    self.init(name: name, output: .success(output))
  }

  let name: String
  let isReadonly: Bool
  let isAvailableInChatMode: @Sendable (ChatMode) -> Bool

  var description: String { "tool for testing" }
  var inputSchema: JSON { .object([:]) }

  func isAvailable(in _: ChatFoundation.ChatMode) -> Bool {
    true
  }

  func use(toolUseId: String, input: Input, context _: ToolExecutionContext) -> TestToolUse<Input, Output> {
    TestToolUse<Input, Output>(callingTool: self, toolUseId: toolUseId, input: input, output: output, isReadonly: isReadonly)
  }

  private let output: Result<Output, Error>
}

extension [AssistantMessageContent] {
  mutating func append(toolUse: any ToolUse) {
    append(.tool(ToolUseMessage(toolUse: toolUse)))
  }
}

// MARK: - TestToolInput

struct TestToolInput: Codable & Sendable {
  let file: String
}

let okServerResponse = Data()

// MARK: - TestChatContext

struct TestChatContext: ChatContext {

  init(
    projectRoot: URL,
    prepareForWriteToolUse: @escaping @Sendable () async -> Void = { })
  {
    self.projectRoot = projectRoot
    self.prepareForWriteToolUse = prepareForWriteToolUse
  }

  let projectRoot: URL

  let prepareForWriteToolUse: @Sendable () async -> Void
}
