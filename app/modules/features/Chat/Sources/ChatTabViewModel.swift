// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFoundation
import CheckpointServiceInterface
import Combine
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

  init(id: UUID = UUID(), name: String = "New Chat", messages: [ChatMessage] = [], mode: ChatMode = .agent) {
    self.id = id
    self.name = name
    self.messages = messages
    events = messages.flatMap { message in
      message.content.map { .message(.init(content: $0, role: message.role)) }
    }
    self.mode = mode
    input = ChatInputViewModel()

    workspaceRootObservation = xcodeObserver.statePublisher.sink { @Sendable state in
      guard state.focusedWorkspace != nil else { return }
      Task { @MainActor in
        _ = self.updateProjectRoot()
        self.workspaceRootObservation = nil
      }
    }
  }

  let id: UUID
  var name: String
  var events: [ChatEvent]
  var mode: ChatMode
  var input: ChatInputViewModel
  // TODO: look at making this a private(set). It's needed for a finding, that ideally would be readonly
  var isStreamingResponse = false

  private(set) var messages: [ChatMessage] = []

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
    let messageContent = ChatMessageContent.text(ChatMessageTextContent(
      projectRoot: projectRoot,
      text: textInput.string.string,
      attachments: attachments))
    let userMessage = ChatMessage(
      content: [messageContent],
      role: .user)

    events.append(.message(.init(content: messageContent, role: .user)))
    messages.append(userMessage)

    // Send the message to the server and stream the response.
    do {
      let tools: [any Tool] = toolsPlugin.tools(for: mode)
      streamingTask = Task {
        async let done = llmService.sendMessage(
          messageHistory: messages.apiFormat,
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

                  let newMessageState = ChatMessage(
                    content: newMessage.content.map { $0.domainFormat(projectRoot: projectRoot) },
                    role: .assistant)
                  messages.append(newMessageState)

                  for await update in newMessage.updates {
                    // new message content was received
                    if let newContent = update.content.last {
                      var content = newMessageState.content
                      let newContent = newContent.domainFormat(projectRoot: projectRoot)
                      content.append(newContent)
                      events.append(.message(.init(content: newContent, role: .assistant)))
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
      defaultLogger.error("Error sending message", error)
      streamingTask = nil
    }
  }

  func handleRestore(checkpoint: Checkpoint) {
    Task {
      do {
        try await checkpointService.restore(checkpoint: checkpoint)
      } catch {
        defaultLogger.error("Failed to restore checkpoint", error)
      }
    }
  }

  @ObservationIgnored private var workspaceRootObservation: AnyCancellable?

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
      // Create checkpoint and add it to events before the tool call is executed.
      let checkpoint = try await checkpointService.createCheckpoint(
        projectRoot: projectRoot,
        taskId: "main",
        message: "checkpoint")
      if !events.compactMap(\.checkpoint).contains(where: { $0.id == checkpoint.id }) {
        // Execute on the main actor to update the UI
        await MainActor.run {
          // Find the index of the last message to insert the checkpoint after it
          if let lastMessageIndex = events.lastIndex(where: { $0.message != nil }) {
            // Insert the checkpoint after the last message
            events.insert(.checkpoint(checkpoint), at: lastMessageIndex + 1)
          } else {
            // Fallback if no messages found
            events.append(.checkpoint(checkpoint))
          }
        }
      }
    } catch {
      defaultLogger.error("Failed to create checkpoint: \(error.localizedDescription)")
    }
  }

  private func updateProjectRoot() -> URL {
    if let projectRoot {
      return projectRoot
    }
    if let workspace = xcodeObserver.state.focusedWorkspace {
      let projectRoot = fileManager.isDirectory(at: workspace.url) ? workspace.url.deletingLastPathComponent() : workspace.url

      Task {
        do {
          let workspaceContextMessage = try await createContextMessage(for: workspace, projectRoot: projectRoot)
          messages.append(.init(content: [.nonUserFacingText(workspaceContextMessage)], role: .user))
        } catch {
          defaultLogger.error("Failed to create context message for workspace", error)
        }
      }

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
  case message(_ message: ChatMessageContentWithRole)
  case checkpoint(_ checkpoint: Checkpoint)

  var message: ChatMessageContentWithRole? {
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
