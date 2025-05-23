// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import ConcurrencyFoundation
import DependencyFoundation
import Foundation
import JSONFoundation
import LLMServiceInterface
import LoggingServiceInterface
import ServerServiceInterface
import SettingsServiceInterface
import SwiftOpenAI
import ToolFoundation

// MARK: - DefaultLLMService

/// NOT USED. TODO: remove once the tests have been ported to the replacement.
final class DefaultLLMService: LLMService {

  init(server: Server, settingsService: SettingsService) {
    self.server = server
    self.settingsService = settingsService

    tmp = DefaultLLMService2(
      server: server,
      settingsService: settingsService)
  }

  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any ToolFoundation.Tool] = [],
    model: LLMModel,
    context: any ChatContext,
    migrated: Bool = false,
    handleUpdateStream: (UpdateStream) -> Void)
    async throws -> [AssistantMessage]
  {
    if migrated {
      return try await tmp.sendMessage(
        messageHistory: messageHistory,
        tools: tools,
        model: model,
        context: context,
        migrated: migrated,
        handleUpdateStream: handleUpdateStream)
    }

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
          await messageHistory.append(Self.execute(toolUseRequest: toolUseRequest, context: context))
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
    let params = try Schema.SendMessageRequestParams(
      messages: messageHistory,
      system: nil,
      projectRoot: context.projectRoot?.path,
      tools: tools.map { .init(name: $0.name, description: $0.description, inputSchema: $0.inputSchema) },
      model: model.id,
      provider: provider(for: model))
    let data = try JSONEncoder().encode(params)

    let result = MutableCurrentValueStream<AssistantMessage>(AssistantMessage(content: []))
    handleUpdateStream(result)

    let isTaskCancelled = Atomic(false)

    return try await withTaskCancellationHandler(operation: {
      do {
        let err = Atomic<Error?>(nil)
        _ = try await server.postRequest(path: "sendMessage", data: data) { chunk in
          guard !isTaskCancelled.value else {
            // This should not be necessary. Cancelling the task should make the post request fail with an error.
            // TODO: look at removing this, which can also lead to `.finish()` being called twice on the stream.
            assertionFailure("Task was cancelled but we still received a chunk")
            result.content.last?.asText?.finish()
            result.finish()
            return
          }

          do {
            let event = try JSONDecoder().decode(Schema.StreamedResponseChunk.self, from: chunk)
            switch event {
            case .textDelta(let text):
              if let textContent = result.content.last?.asText {
                // We received a new text chunk, we'll append it to the last text content.
                let lastMessage = textContent.value
                let newMessage = TextContentMessage(
                  content: lastMessage.content + text.text,
                  deltas: lastMessage.deltas + [text.text])
                textContent.update(with: newMessage)
              } else {
                // Create a new text content.
                let newContent = TextContentMessage(content: text.text, deltas: [text.text])
                var content = result.content
                content.append(.text(MutableCurrentValueStream(newContent)))
                result.update(with: AssistantMessage(content: content))
              }

            case .toolUseRequest(let toolInput):
              // Finish the previous text message.
              result.content.last?.asText?.finish()

              // Sent a tool call request.
              var content = result.content
              let request = ToolUseRequestMessage(
                name: toolInput.name,
                input: toolInput.input,
                id: toolInput.id)

              if let tool = tools.first(where: { $0.name == request.name }) {
                do {
                  let data = try JSONEncoder().encode(request.input)
                  try content.append(toolUse: tool.use(
                    toolUseId: request.id,
                    input: data,
                    isInputComplete: true,
                    context: ToolExecutionContext(project: context.project, projectRoot: context.projectRoot)))
                } catch {
                  // If the above fails, this is because the input could not be parsed by the tool.
                  content.append(toolUse: FailedToolUse(
                    toolUseId: request.id,
                    toolName: request.name,
                    error: Self.failedToParseToolInputError(toolName: request.name, error: error)))
                }
              } else {
                // Tool not found
                content.append(toolUse: FailedToolUse(
                  toolUseId: request.id,
                  toolName: request.name,
                  error: Self.missingToolError(toolName: request.name)))
              }
              result.update(with: AssistantMessage(content: content))

            case .responseError(let error):
              // We received an error from the server.
              err.mutate { $0 = $0 ?? AppError(message: error.message) }
            }
          } catch {
            // TODO: Try to decode the chunk as an error
            // Looks like {"success":false,"status":500,"message":"Failed to process message.","stack":{}}
            defaultLogger.error("Chunk with decoding error:\(String(data: chunk, encoding: .utf8) ?? "") \(error)")
            err.mutate { $0 = $0 ?? error }
          }
        }
        if let error = err.value {
          throw error
        }
        defaultLogger.log("Finished streaming response")
        result.content.last?.asText?.finish()
        result.finish()
      } catch {
        defaultLogger.error("Finished streaming response with error \(error)")
        result.content.last?.asText?.finish()
        result.finish()

        throw error
      }

      return await result.lastValue
    }, onCancel: {
      isTaskCancelled.mutate { $0 = true }
    })
  }

  private let tmp: DefaultLLMService2

  private let settingsService: SettingsService
  private let server: Server

  /// Execute a tool use request.
  /// This returns a message representing the result of the tool use, and broadcast the execution status to the update stream.
  private static func execute(
    toolUseRequest: ToolUseMessage,
    context: ChatContext)
    async -> Schema.Message
  {
    let toolUse = toolUseRequest.toolUse

    do {
      if !toolUse.isReadonly {
        await context.prepareForWriteToolUse()
      }
      toolUse.startExecuting()
      let toolOutput = try await toolUse.result

      // TODO: try to avoid this.
      let data = try JSONEncoder().encode(toolOutput)
      let json = try JSONDecoder().decode(JSON.Value.self, from: data)

      let toolResult = Schema.ToolResultMessage(
        toolUseId: toolUse.toolUseId,
        result: .toolResultSuccessMessage(.init(success: json)))
      return .init(role: .user, content: [.toolResultMessage(toolResult)])
    } catch {
      let toolResult = Schema.ToolResultMessage(
        toolUseId: toolUse.toolUseId,
        result: .toolResultFailureMessage(.init(failure: .string(error.localizedDescription))))
      return .init(role: .user, content: [.toolResultMessage(toolResult)])
    }
  }

  private static func missingToolError(toolName name: String) -> Error {
    NSError(
      domain: "ToolUseError",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: "Missing tool \(name)"])
  }

  private static func failedToParseToolInputError(toolName name: String, error: Error) -> Error {
    NSError(
      domain: "ToolUseError",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Could not parse the input for tool \(name): \(error.localizedDescription)"])
  }

  private func provider(for model: LLMModel) throws -> Schema.APIProvider {
    let settings = settingsService.values()
    switch model {
    case .claudeSonnet40, .claudeSonnet37:
      guard let anthropicSettings = settings.anthropicSettings else {
        throw AppError(message: "Anthropic API not configured")
      }
      return .init(name: .anthropic, settings: .init(apiKey: anthropicSettings.apiKey, baseUrl: anthropicSettings.apiUrl))

    case .gpt4o, .gpt4o_mini, .o1:
      guard let openAISettings = settings.openAISettings else {
        throw AppError(message: "Open AI API not configured")
      }
      return .init(name: .openai, settings: .init(apiKey: openAISettings.apiKey, baseUrl: openAISettings.apiUrl))

    default:
      throw AppError(message: "Unsupported model \(model)")
    }
  }

}

extension BaseProviding where
  Self: ServerProviding,
  Self: SettingsServiceProviding
{
  public var llmService: LLMService {
    shared {
      DefaultLLMService(
        server: server,
        settingsService: settingsService)
    }
  }
}

extension [AssistantMessageContent] {
  mutating func append(toolUse: any ToolUse) {
    append(.tool(ToolUseMessage(toolUse: toolUse)))
  }
}
