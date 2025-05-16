// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFoundation
import CheckpointServiceInterface
import Dependencies
import Foundation
import FoundationInterfaces
import LLMServiceInterface
import LoggingServiceInterface
import Observation
import ServerServiceInterface
import ToolFoundation
import XcodeObserverServiceInterface

// MARK: - ChatTabViewModel

@MainActor @Observable
final class ChatTabViewModel: Identifiable, Equatable {

  init(id: UUID = UUID(), name: String = "New Chat", events: [ChatEvent] = [], mode: ChatMode = .agent) {
    self.id = id
    self.name = name
    self.events = events
    self.mode = mode
    input = ChatInputViewModel()
  }

  let id: UUID
  var name: String
  var events: [ChatEvent]
  var mode: ChatMode
  var input: ChatInputViewModel
  // TODO: look at making this a private(set). It's needed for a finding, that ideally would be readonly
  var isStreamingResponse = false

  nonisolated static func ==(lhs: ChatTabViewModel, rhs: ChatTabViewModel) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  func cancelCurrentMessage() {
    streamingTask?.cancel()
    streamingTask = nil
  }

  /// Are we queing too much on the main thread?
  @MainActor
  func sendMessage() async {
    let projectRoot = updateProjectRoot()

    guard streamingTask == nil else {
      defaultLogger.error("not sending as already streaming")
      return
    }
    let textInput = input.textInput
    let attachments = input.attachments

    input.textInput = TextInput()
    input.attachments = []

    // TODO: reformat the string sent to the LLM
    let userMessage = ChatMessage(
      content: [.text(ChatMessageTextContent(text: textInput.string.string, attachments: attachments))],
      role: .user)

    events.append(.message(userMessage))

    // Send the message to the server and stream the response.
    do {
      let tools: [any Tool] = toolsPlugin.tools(for: mode)
      streamingTask = Task {
        async let done = llmService.sendMessage(
          messageHistory: events.compactMap(\.message).apiFormat,
          tools: tools,
          model: self.input.selectedModel,
          context: DefaultChatContext(
            projectRoot: projectRoot,
            prepareForWriteToolUse: { [weak self] in await self?.handlePrepareForWriteToolUse() }),
          migrated: true,
          handleUpdateStream: { newMessages in
            Task { @MainActor [weak self] in
              guard let self else { return }
              var trackedMessages = Set<UUID>()
              for await update in newMessages.updates {
                for newMessage in update.filter({ !trackedMessages.contains($0.id) }) {
                  trackedMessages.insert(newMessage.id)

                  let newMessageState = ChatMessage(content: newMessage.content.map(\.domainFormat), role: .assistant)
                  events.append(.message(newMessageState))

                  for await update in newMessage.updates {
                    // new message content was received
                    if let newContent = update.content.last {
                      var content = newMessageState.content
                      content.append(newContent.domainFormat)
                      newMessageState.content = content
                    }
                  }
                }
              }
            }
          })
        _ = try await done
      }

      try await streamingTask?.value
      streamingTask = nil
    } catch {
      // TODO: add error message to the UI.
      defaultLogger.error("Error sending message: \(error.localizedDescription)")
      streamingTask = nil
    }
  }

  func handleRestore(checkpoint: Checkpoint) {
    Task {
      do {
        try await checkpointService.restore(checkpoint: checkpoint)
      } catch {
        defaultLogger.error("Failed to restore checkpoint: \(error.localizedDescription)")
      }
    }
  }

  @ObservationIgnored private var projectRoot: URL?

  @ObservationIgnored
  @Dependency(\.toolsPlugin) private var toolsPlugin: ToolsPlugin

  @MainActor @ObservationIgnored @Dependency(\.llmService) private var llmService: LLMService

  @ObservationIgnored
  @Dependency(\.xcodeObserver) private var xcodeObserver

  @ObservationIgnored
  @Dependency(\.fileManager) private var fileManager: FileManagerI

  @ObservationIgnored
  @Dependency(\.checkpointService) private var checkpointService: CheckpointService

  private var streamingTask: Task<Void, any Error>? = nil {
    didSet {
      isStreamingResponse = streamingTask != nil
    }
  }

  private func handlePrepareForWriteToolUse() async {
    let projectRoot = updateProjectRoot()
    do {
      let checkpoint = try await checkpointService.createCheckpoint(
        projectRoot: projectRoot,
        taskId: "main",
        message: "checkpoint")
      if !events.compactMap(\.checkpoint).contains(where: { $0.id == checkpoint.id }) {
        events.append(.checkpoint(checkpoint))
      }
    } catch {
      defaultLogger.error("Failed to create checkpoint: \(error.localizedDescription)")
    }
  }

  private func updateProjectRoot() -> URL {
    if let projectRoot {
      return projectRoot
    }
    if let workspaceURL = xcodeObserver.state.focusedWorkspace?.url {
      let projectRoot = fileManager.isDirectory(at: workspaceURL) ? workspaceURL.deletingLastPathComponent() : workspaceURL

      self.projectRoot = projectRoot
      return projectRoot
    }
    return URL(filePath: "/")
  }

}

// MARK: - DefaultChatContext

struct DefaultChatContext: ChatContext {

  init(
    projectRoot: URL,
    prepareForWriteToolUse: @escaping @Sendable () async -> Void)
  {
    self.projectRoot = projectRoot
    self.prepareForWriteToolUse = prepareForWriteToolUse
  }

  let projectRoot: URL
  let prepareForWriteToolUse: @Sendable () async -> Void
}

// MARK: - ChatEvent

enum ChatEvent: Identifiable {
  case message(_ message: ChatMessage)
  case checkpoint(_ checkpoint: Checkpoint)

  var message: ChatMessage? {
    if case .message(let message) = self {
      return message
    }
    return nil
  }

  var checkpoint: Checkpoint? {
    if case .checkpoint(let checkpoint) = self {
      return checkpoint
    }
    return nil
  }

  var id: String {
    switch self {
    case .message(let message):
      message.id.uuidString
    case .checkpoint(let checkpoint):
      checkpoint.id
    }
  }
}
