// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import ConcurrencyFoundation
import DependencyFoundation
import Foundation
import FoundationInterfaces
import JSONFoundation
import LLMFoundation
import LLMServiceInterface
import LoggingServiceInterface
import ServerServiceInterface
import SettingsServiceInterface
import ToolFoundation

// MARK: - DefaultLLMService

final class DefaultLLMService: LLMService {

  init(server: Server, settingsService: SettingsService, userDefaults: UserDefaultsI) {
    self.server = server
    self.settingsService = settingsService

    #if DEBUG
    repeatDebugHelper = RepeatDebugHelper(userDefaults: userDefaults)
    #endif
  }

  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any ToolFoundation.Tool] = [],
    model: LLMModel,
    context: any ChatContext,
    handleUpdateStream: (UpdateStream) -> Void)
    async throws -> [AssistantMessage]
  {
    let response = MutableCurrentValueStream<[CurrentValueStream<AssistantMessage>]>([])
    handleUpdateStream(response)

    do {
      var messageHistory = messageHistory

      // Iterate until we have received a response with no tool use request.
      while true {
        let newMessage = try await sendOneMessage(
          messageHistory: messageHistory,
          tools: tools,
          model: model,
          context: context)
        { newMessage in
          // Add the new message to the response stream.
          var newMessages = response.value
          newMessages.append(newMessage)
          response.update(with: newMessages)
        }

        // The new message is now entirely received. We can deal with tool calls.
        let toolUseRequests: [ToolUseMessage] = newMessage.content.compactMap { content in
          content.asToolUseRequest
        }
        if toolUseRequests.isEmpty {
          // No tool use, we are done.
          break
        }

        // Add to the message history the message just received.
        // This is important as the assistant needs to see the message with tool calls before the tool use results.
        try messageHistory.append(newMessage.message)

        // Execute each tool call.
        for toolUseRequest in toolUseRequests {
          try Task.checkCancellation()
          await messageHistory.append(Self.waitForResult(of: toolUseRequest, context: context))
        }
      }
      response.finish()
    } catch {
      response.finish()
      throw error
    }

    // At this point all the assistant messages have been received.
    // Return them to the caller.
    var messages: [AssistantMessage] = []
    for message in response.value {
      let finalMessage = await message.lastValue
      messages.append(finalMessage)
    }
    return messages
  }

  /// Call the `sendMessage` endpoint once.
  /// - Returns: The message received from the assistant.
  /// - Parameters:
  ///   - messageHistory: The historical context of all messages in the conversation. The last message is expected to be the last one sent by the user.
  ///   - tools: The tools available to the assistant.
  ///   - handleUpdateStream: A callback called synchronously with a stream that will broadcast updates about received messages. This can be usefull if you want to display the messages as they are streamed.
  func sendOneMessage(
    messageHistory: [Schema.Message],
    tools: [any ToolFoundation.Tool] = [],
    model: LLMModel,
    context: any ChatContext,
    handleUpdateStream: (CurrentValueStream<AssistantMessage>) -> Void)
    async throws -> AssistantMessage
  {
    let settings = settingsService.values()
    let (provider, providerSettings) = try settings.provider(for: model)
    let customInstructions: String? = {
      switch context.chatMode {
      case .ask:
        return settings.customInstructions.askMode.isEmpty ? nil : settings.customInstructions.askMode
      case .agent:
        return settings.customInstructions.agentMode.isEmpty ? nil : settings.customInstructions.agentMode
      }
    }()
    let promptConfiguration = PromptConfiguration(
      projectRoot: context.projectRoot,
      mode: context.chatMode,
      customInstructions: customInstructions)
    let params = try Schema.SendMessageRequestParams(
      messages: messageHistory,
      system: Prompt.defaultPrompt(configuration: promptConfiguration),
      projectRoot: context.projectRoot?.path,
      tools: tools.map { .init(name: $0.name, description: $0.description, inputSchema: $0.inputSchema) },
      model: provider.id(for: model),
      provider: .init(provider: provider, settings: providerSettings))
    let data = try JSONEncoder().encode(params)

    let result = MutableCurrentValueStream<AssistantMessage>(AssistantMessage(content: []))
    handleUpdateStream(result)

    let isTaskCancelled = Atomic(false)

    return try await withTaskCancellationHandler(operation: {
      #if DEBUG
      let stream = {
        if let stream = try? repeatDebugHelper.repeatStream() { return stream }
        return server.streamPostRequest(path: "sendMessage", data: data)
      }()

      let helper = RequestStreamingHelper(
        stream: stream,
        result: result,
        tools: tools,
        context: context,
        isTaskCancelled: { isTaskCancelled.value },
        repeatDebugHelper: repeatDebugHelper)
      #else
      let stream = await server.streamPostRequest(path: "sendMessage", data: data)

      let helper = RequestStreamingHelper(
        stream: stream,
        result: result,
        tools: tools,
        context: context,
        isTaskCancelled: { isTaskCancelled.value })
      #endif

      try await helper.processStream()

      return await result.lastValue
    }, onCancel: {
      isTaskCancelled.mutate { $0 = true }
    })
  }

  #if DEBUG
  private let repeatDebugHelper: RepeatDebugHelper
  #endif
  private let settingsService: SettingsService
  private let server: Server

  /// Wait for the result of a tool use request.
  /// This returns a message representing the result of the tool use, and broadcast the execution status to the update stream.
  private static func waitForResult(
    of toolUseRequest: ToolUseMessage,
    context _: ChatContext)
    async -> Schema.Message
  {
    let toolUse = toolUseRequest.toolUse

    do {
      let toolOutput = try await toolUse.result

      // TODO: try to avoid this.
      let data = try JSONEncoder().encode(toolOutput)
      let json = try JSONDecoder().decode(JSON.Value.self, from: data)

      let toolResult = Schema.ToolResultMessage(
        toolUseId: toolUse.toolUseId,
        toolName: toolUse.toolName,
        result: .toolResultSuccessMessage(.init(success: json)))
      return .init(role: .tool, content: [.toolResultMessage(toolResult)])
    } catch {
      let toolResult = Schema.ToolResultMessage(
        toolUseId: toolUse.toolUseId,
        toolName: toolUse.toolName,
        result: .toolResultFailureMessage(.init(failure: .string(error.localizedDescription))))
      return .init(role: .tool, content: [.toolResultMessage(toolResult)])
    }
  }

}

extension BaseProviding where
  Self: ServerProviding,
  Self: SettingsServiceProviding,
  Self: UserDefaultsProviding
{
  public var llmService: LLMService {
    shared {
      DefaultLLMService(
        server: server,
        settingsService: settingsService,
        userDefaults: sharedUserDefaults)
    }
  }
}

extension [AssistantMessageContent] {
  mutating func append(toolUse: any ToolUse) {
    append(.tool(ToolUseMessage(toolUse: toolUse)))
  }
}

extension Schema.APIProvider {
  init(provider: LLMProvider, settings: LLMProviderSettings) throws {
    let apiProviderName: Schema.APIProviderName = try {
      switch provider {
      case .anthropic:
        return .anthropic
      case .openAI:
        return .openai
      case .openRouter:
        return .openrouter
      default:
        throw AppError(message: "Unsupported provider \(provider.name)")
      }
    }()
    self = .init(name: apiProviderName, settings: .init(apiKey: settings.apiKey, baseUrl: settings.baseUrl))
  }
}
