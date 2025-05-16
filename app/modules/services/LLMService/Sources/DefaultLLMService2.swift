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

// MARK: - DefaultLLMService2

final class DefaultLLMService2: LLMService {

  init(server: Server, settingsService: SettingsService) {
    self.server = server
    self.settingsService = settingsService
  }

  func sendMessage(
    messageHistory: [Schema.Message],
    tools: [any ToolFoundation.Tool] = [],
    model: LLMModel,
    context: any ChatContext,
    migrated _: Bool,
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
    model _: LLMModel,
    context: any ChatContext,
    handleUpdateStream: (CurrentValueStream<AssistantMessage>) -> Void)
    async throws -> AssistantMessage
  {
    let result = MutableCurrentValueStream<AssistantMessage>(AssistantMessage(content: []))
    handleUpdateStream(result)

    let isTaskCancelled = Atomic(false)

    return try await withTaskCancellationHandler(operation: {
      do {
        let err = Atomic<Error?>(nil)

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 360 // e.g., 360 seconds or more.
        let service = OpenAIServiceFactory.service(
          apiKey: settingsService.value(for: \.anthropicSettings)?.apiKey ?? "",
          overrideBaseURL: "https://api.anthropic.com",
          configuration: configuration,
          overrideVersion: "v1")

        let parameters = ChatCompletionParameters(
          messages: [.init(role: .system, content: .text(Prompt.defaultPrompt(projectRoot: context.projectRoot)))] +
            messageHistory.flatMap { message in message.mapped },
          model: .custom("claude-3-7-sonnet-20250219"),
          tools: tools.map(\.mapped))
        let stream = try await service.startStreamedChat(parameters: parameters)
        
          var currentToolUseToolName: String? = nil
          var currentToolUseId: String? = nil
          var currentToolUsePartiaInput: String? = nil
          var currentToolUse: (any ToolUse)? = nil

        let wrapToolUse: () throws -> Void = {
          defer { toolRequest = nil }
          guard let toolRequest else { return }
          // Finish the previous text message.
          result.content.last?.asText?.finish()

          guard
            let toolName = toolRequest.name, let toolUseId = toolRequest.id,
            let data = toolRequest.arguments.data(using: .utf8)
          else {
            throw AppError("Could not convert tool request to data")
          }
          let input = try JSONDecoder().decode(JSON.self, from: data)

          // Create a tool call request.
          var content = result.content
          let request = ToolUseRequestMessage(
            name: toolName,
            input: input,
            id: toolUseId)

          if let tool = tools.first(where: { $0.name == request.name }) {
            do {
              try content.append(toolUse: tool.use(
                toolUseId: request.id,
                input: request.input,
                context: ToolExecutionContext(projectRoot: context.projectRoot)))
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
        }

        do {
          for try await chunk in stream {
            guard !isTaskCancelled.value else {
              // This should not be necessary. Cancelling the task should make the post request fail with an error.
              // TODO: look at removing this, which can also lead to `.finish()` being called twice on the stream.
              assertionFailure("Task was cancelled but we still received a chunk")
              result.content.last?.asText?.finish()
              result.finish()
              break
            }

            guard let event = chunk.choices?.first?.delta else { continue }
            if let text = event.content {
              try wrapToolUse()
              if let textContent = result.content.last?.asText {
                // We received a new text chunk, we'll append it to the last text content.
                let lastMessage = textContent.value
                let newMessage = TextContentMessage(
                  content: lastMessage.content + text,
                  deltas: lastMessage.deltas + [text])
                textContent.update(with: newMessage)
              } else {
                // Create a new text content.
                let newContent = TextContentMessage(content: text, deltas: [text])
                var content = result.content
                content.append(.text(MutableCurrentValueStream(newContent)))
                result.update(with: AssistantMessage(content: content))
              }
            } else if let toolUse = event.toolCalls?.first {
                currentToolUseId = currentToolUseId ?? toolUse.id
                currentToolUseToolName = currentToolUseToolName ?? toolUse.function.name
                currentToolUsePartiaInput = currentToolUsePartiaInput ?? ""
                currentToolUsePartiaInput += toolUse.function.arguments
                
                // TODO: convert currentToolUsePartiaInput to valid json
                
                if let currentToolUse {
                    do {
                        let data = currentToolUsePartiaInput.data(using: .utf8)
                        
                    }
                    currentToolUse.receive(inputUpdate: <#T##(any ToolUse).Input#>)
                    else if let name = currentToolUseToolName, let id = currentToolUseId {
                    // ready to start streaming tool use input
                    
                }
            }
          }

          try wrapToolUse()
        } catch {
          // TODO: Try to decode the chunk as an error
          // Looks like {"success":false,"status":500,"message":"Failed to process message.","stack":{}}
          defaultLogger.error("Error processing chunk")
          err.mutate { $0 = $0 ?? error }
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

}

extension Schema.Message.Role {
  var mapped: ChatCompletionParameters.Message.Role {
    switch self {
    case .assistant:
      .assistant
    case .user:
      .user
    case .system:
      .system
    }
  }
}

// extension Schema.MessageContent {
//  var mapped: ChatCompletionParameters.Message.ContentType {
//    switch self {
//    case .textMessage(let message):
//      return .text(message.text)
//    case .toolResultMessage(let message):
//      break
//    case .toolUseRequest(let message):
//      break
//    }
//    fatalError("Tool use request not supported")
//  }
// }

extension ToolFoundation.Tool {
  var mapped: ChatCompletionParameters.Tool {
    ChatCompletionParameters.Tool(function: .init(
      name: name,
      strict: true,
      description: description,
      parameters: inputSchema.mapped))
  }
}

extension JSON {
  var mapped: JSONSchema {
    let data = try! JSONEncoder().encode(self)
    return try! JSONDecoder().decode(JSONSchema.self, from: data)
  }
}

extension Schema.Message {
  var mapped: [ChatCompletionParameters.Message] {
    var result = [ChatCompletionParameters.Message]()
    for content in content {
      switch content {
      case .textMessage(let message):
        var content = [ChatCompletionParameters.Message.ContentType.MessageContent]()
        content.append(.text(message.text))
        if let attachments = message.attachments, !attachments.isEmpty {
          content.append(.text("You can use this context provided by the user:"))
          for attachment in attachments {
            switch attachment {
            // TODO: if we use XML more, look into using https://github.com/CoreOffice/XMLCoder
            case .fileAttachment(let a):
              content.append(.text("<fileAttachment><path>\(a.path)</path><content>\(a.content)</content></fileAttachment>"))

            case .fileSelectionAttachment(let a):
              content
                .append(
                  .text(
                    "<fileSelectionAttachment><path>\(a.path)</path><startLine>\(a.startLine)</startLine><endLine>\(a.endLine)</endLine><content>\(a.content)</content></fileSelectionAttachment>"))

            case .imageAttachment(let a):
              content.append(.imageUrl(.init(url: URL(fileURLWithPath: a.url))))

            case .buildErrorAttachment(let a):
              content
                .append(
                  .text(
                    "<buildError><path>\(a.filePath)</path><line>\(a.line)</line><column>\(a.column)</column><content>\(a.message)</content></buildError>"))
            }
          }
          content.append(.text("End of user provided context"))
        }
        result.append(.init(role: role.mapped, content: .contentArray(content)))

      case .toolResultMessage(let message):
        result.append(.init(
          role: .tool, // Is open AI fine with this?
          content: .text(String(data: try! JSONEncoder().encode(message.result), encoding: .utf8)!),
          toolCallID: message.toolUseId))

      case .toolUseRequest(let message):
        result.append(.init(
          role: role.mapped,
          content: ChatCompletionParameters.Message.ContentType.contentArray([]),
          toolCalls: [
            .init(
              id: message.id,
              function: .init(
                arguments: String(data: try! JSONEncoder().encode(message.input), encoding: .utf8)!,
                name: message.name)),
          ]))
      }
    }
    return result
  }
}

// MARK: - PartialToolUse

struct PartialToolUse {
  var id: String?
  var name: String?
  var arguments: String
    
    var parseableJSON: Data?
}
