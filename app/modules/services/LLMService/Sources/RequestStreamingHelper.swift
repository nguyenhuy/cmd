// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ChatFoundation
import ConcurrencyFoundation
import Foundation
import LLMServiceInterface
import ServerServiceInterface
import ToolFoundation

/// Receives streamed data from the serevr, and processes it to update the `result` stream with the new content.
/// Parse tool request, handle text and tool streaming.,
final class RequestStreamingHelper {
  #if DEBUG
  /// - Parameters:
  ///   - stream: The stream of data received from the server.
  ///   - result: The processed result that should be updated as we receive new data.
  ///   - tools: The list of tools available to the assistant.
  ///   - context: The context in which the request is executed.
  ///   - isTaskCancelled: A closure that returns whether the task has been cancelled.
  init(
    stream: AsyncThrowingStream<Data, any Error>,
    result: MutableCurrentValueStream<AssistantMessage>,
    tools: [any ToolFoundation.Tool],
    context: any ChatContext,
    isTaskCancelled: @escaping () -> Bool,
    repeatDebugHelper: RepeatDebugHelper = .init())
  {
    self.stream = stream
    self.result = result
    self.tools = tools
    self.context = context
    self.isTaskCancelled = isTaskCancelled
    self.repeatDebugHelper = repeatDebugHelper
  }
  #else
  /// - Parameters:
  ///   - stream: The stream of data received from the server.
  ///   - result: The processed result that should be updated as we receive new data.
  ///   - tools: The list of tools available to the assistant.
  ///   - context: The context in which the request is executed.
  ///   - isTaskCancelled: A closure that returns whether the task has been cancelled.
  init(
    stream: AsyncThrowingStream<Data, any Error>,
    result: MutableCurrentValueStream<AssistantMessage>,
    tools: [any ToolFoundation.Tool],
    context: any ChatContext,
    isTaskCancelled: @escaping () -> Bool)
  {
    self.stream = stream
    self.result = result
    self.tools = tools
    self.context = context
    self.isTaskCancelled = isTaskCancelled
    repeatDebugHelper = repeatDebugHelper
  }
  #endif

  let result: MutableCurrentValueStream<AssistantMessage>
  let stream: AsyncThrowingStream<Data, any Error>
  let tools: [any ToolFoundation.Tool]
  let context: any ChatContext
  var err: Error? = nil
  var streamingToolUse: (any ToolUse)? = nil
  var streamingToolUseInput = ""

  /// Handle all the streamed data, updating the `result` stream with the new content.
  func processStream() async throws {
    for try await chunk in stream {
      #if DEBUG
      repeatDebugHelper.receive(chunk: chunk)
      #endif
      guard !isTaskCancelled() else {
        // This should not be necessary. Cancelling the task should make the post request fail with an error.
        // TODO: look at removing this, which can also lead to `.finish()` being called twice on the stream.
        assertionFailure("Task was cancelled but we still received a chunk")
        result.content.last?.asText?.finish()
        result.finish()
        break
      }

      let event = try JSONDecoder().decode(Schema.StreamedResponseChunk.self, from: chunk)

      switch event {
      case .textDelta(let textDelta):
        handle(textDelta: textDelta)
      case .toolUseDelta(let toolUseDelta):
        await handle(toolUseDelta: toolUseDelta)
      case .toolUseRequest(let toolUseRequest):
        await handle(toolUseRequest: toolUseRequest)
      case .responseError(let error):
        // We received an error from the server.
        err = err ?? AppError(message: error.message)
      }
    }
    if let err {
      throw err
    }
    finish()
  }

  /// Wrap up the stream. When the stream is process without failure this is already called.
  func finish() {
    endTextContentIfNecesssary()
    result.finish()
    validate()

    #if DEBUG
    repeatDebugHelper.streamCompleted()
    #endif
  }

  private let isTaskCancelled: () -> Bool

  #if DEBUG
  private let repeatDebugHelper: RepeatDebugHelper
  #endif

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

  private func validate() { let toolUseIds = result.content.compactMap { $0.asToolUseRequest?.toolUse.toolUseId }
    if toolUseIds.count != Set(toolUseIds).count {
      // We have duplicate tool use IDs in the result. This is an error.
      assertionFailure()
    }
  }

  private func handle(textDelta: Schema.TextDelta) {
    if let textContent = result.content.last?.asText {
      // We received a new text chunk, we'll append it to the last text content.
      let lastMessage = textContent.value
      let newMessage = TextContentMessage(
        content: lastMessage.content + textDelta.text,
        deltas: lastMessage.deltas + [textDelta.text])
      textContent.update(with: newMessage)
    } else {
      // Create a new text content.
      let newContent = TextContentMessage(content: textDelta.text, deltas: [textDelta.text])
      var content = result.content
      content.append(.text(MutableCurrentValueStream(newContent)))
      result.update(with: AssistantMessage(content: content))
    }
  }

  private func handle(toolUseDelta: Schema.ToolUseDelta) async {
    endTextContentIfNecesssary()

    let toolName = toolUseDelta.toolName
    let toolUseId = toolUseDelta.toolUseId

    guard let tool = tools.first(where: { $0.name == toolName }) else {
      // The tool is not known. This is an error.
      // We don't handle the error on every partial update. We expect to later receive the same erronous tool name as a complete tool use request where we'll handle it.
      return
    }
    guard tool.canInputBeStreamed else {
      // The tool doesn't support streaming input. It'll be called at a latter point with the full input.
      return
    }

    streamingToolUseInput += toolUseDelta.inputDelta

    do {
      let (data, isInputComplete) = try streamingToolUseInput.extractPartialJSON()
      var content = result.content
      if let streamingToolUse {
        assert(
          streamingToolUse.toolUseId == toolUseId,
          "Received a tool input while a different tool use is still streaming.")
        // If we already have an existing instance for this tool use, update it with the newly received data.
        try streamingToolUse.receive(inputUpdate: data, isLast: isInputComplete)
      } else {
        // ready to start streaming a new tool use
        let toolUse = try tool.use(
          toolUseId: toolUseId,
          input: data,
          isInputComplete: isInputComplete,
          context: ToolExecutionContext(
            project: context.project,
            projectRoot: context.projectRoot))

        if !toolUse.isReadonly {
          await context.prepareForWriteToolUse()
        }
        streamingToolUse = toolUse
        content.append(toolUse: toolUse)
        result.update(with: AssistantMessage(content: content))
        validate()
      }

      if isInputComplete {
        streamingToolUse?.startExecuting()
        endStreamedToolUse()
      }
    } catch {
      // If the above fails, this is because the input could not be parsed by the tool.
      // While we are receiving the input, it can happen that we don't have enough data to parse the input well
      // so we do nothing with the error here.
      // If the input is not complete when we start receiving the next content, or when the stream ends, we'll set the tool use as failed.
    }
  }

  private func handle(toolUseRequest: Schema.ToolUseRequest) async {
    endTextContentIfNecesssary()

    if let streamingToolUse {
      if streamingToolUse.toolUseId != toolUseRequest.toolUseId {
        assertionFailure("Received a tool use request for a different tool use ID while already streaming a tool use.")
      }
      // If the streamed tool use is still pending data, this is becase an error happened wihle processing the tool use request.
      // We'll clear the partial input and set the tool use to a failed state.

      endStreamedToolUse(withFailure: Self.failedToParseToolInputError(
        toolName: toolUseRequest.toolName,
        error: err ?? AppError(message: "Tool use request failed")))
      return
    }

    if result.content.last?.asToolUseRequest?.toolUse.toolUseId == toolUseRequest.toolUseId {
      // We have already processed the tool use.
      return
    }

    // Deal with non streaming tool use.
    var content = result.content
    let request = ToolUseRequestMessage(
      toolName: toolUseRequest.toolName,
      input: toolUseRequest.input,
      toolUseId: toolUseRequest.toolUseId)

    if let tool = tools.first(where: { $0.name == request.toolName }) {
      do {
        let data = try JSONEncoder().encode(request.input)
        let toolUse = try tool.use(
          toolUseId: request.toolUseId,
          input: data,
          isInputComplete: true,
          context: ToolExecutionContext(project: context.project, projectRoot: context.projectRoot))

        if !toolUse.isReadonly {
          await context.prepareForWriteToolUse()
        }
        content.append(toolUse: toolUse)
        toolUse.startExecuting()

      } catch {
        // If the above fails, this is because the input could not be parsed by the tool.
        content.append(toolUse: FailedToolUse(
          toolUseId: request.toolUseId,
          toolName: request.toolName,
          error: Self.failedToParseToolInputError(toolName: request.toolName, error: error)))
      }
    } else {
      // Tool not found
      content.append(toolUse: FailedToolUse(
        toolUseId: request.toolUseId,
        toolName: request.toolName,
        error: Self.missingToolError(toolName: request.toolName)))
    }
    result.update(with: AssistantMessage(content: content))
    validate()
  }

  private func endStreamedToolUse(withFailure error: Error? = nil) {
    guard let streamingToolUse else { return }
    if let error {
      var content = result.content
      assert(
        content.last?.asToolUseRequest?.toolUse.toolUseId == streamingToolUse.toolUseId,
        "The last content should be the tool use request we are ending.")
      content.removeLast()
      content.append(toolUse: FailedToolUse(
        toolUseId: streamingToolUse.toolUseId,
        toolName: streamingToolUse.toolName,
        error: error))
      result.update(with: AssistantMessage(content: content))
      validate()
    }

    self.streamingToolUse = nil
    streamingToolUseInput = ""
  }

  private func endTextContentIfNecesssary() {
    result.content.last?.asText?.finish()
  }

}
