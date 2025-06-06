// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
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

  #if DEBUG
  convenience init(name: String = "New Chat", messages: [ChatMessage] = []) {
    self.init(
      id: UUID(),
      name: name,
      messages: messages)
  }
  #endif

  convenience init() {
    self.init(
      id: UUID(),
      name: "New Chat",
      messages: [])
  }

  private init(id: UUID, name: String, messages: [ChatMessage]) {
    self.id = id
    self.name = name
    self.messages = messages
    events = messages.flatMap { message in
      message.content.map { .message(.init(content: $0, role: message.role)) }
    }

    input = ChatInputViewModel()

    workspaceRootObservation = xcodeObserver.statePublisher.sink { @Sendable state in
      guard state.focusedWorkspace != nil else { return }
      Task { @MainActor in
        _ = self.updateProjectInfo()
        self.workspaceRootObservation = nil
      }
    }

    @Dependency(\.settingsService) var settingsService
    settingsService.liveValues().map(\.activeModels).removeDuplicates().sink { @Sendable [weak self] activeModels in
      Task { @MainActor in
        self?.hasSomeLLMModelsAvailable = !activeModels.isEmpty
      }
    }.store(in: &cancellables)
  }

  /// Information about the Xcode project/workspace/swift package that this thread is about.
  struct SelectedProjectInfo {
    /// The path to the project
    let path: URL
    /// The dir containing the project (same as the path for a Swift Package)
    let dirPath: URL
    /// Whether the project is a Swift package
    var isSwiftPackage: Bool {
      dirPath != path
    }
  }

  let id: UUID
  var name: String
  var events: [ChatEvent]
  var input: ChatInputViewModel
  // TODO: look at making this a private(set). It's needed for a finding, that ideally would be readonly
  var isStreamingResponse = false
  var hasSomeLLMModelsAvailable = true

  private(set) var messages: [ChatMessage] = []

  private(set) var projectInfo: SelectedProjectInfo?

  nonisolated static func ==(lhs: ChatTabViewModel, rhs: ChatTabViewModel) -> Bool {
    lhs.id == rhs.id
  }

  @MainActor
  func cancelCurrentMessage() {
    streamingTask?.cancel()
    streamingTask = nil
    input.cancelAllPendingToolApprovalRequests()
  }

  /// Are we queing too much on the main thread?
  @MainActor
  func sendMessage() async {
    let projectInfo = updateProjectInfo()

    guard streamingTask == nil else {
      defaultLogger.error("not sending as already streaming")
      return
    }

    // Cancel any pending tool approvals from previous messages
    input.cancelAllPendingToolApprovalRequests()

    guard let selectedModel = input.selectedModel else {
      defaultLogger.error("not sending as no model selected")
      return
    }
    let textInput = input.textInput
    let attachments = input.attachments

    input.textInput = TextInput()
    input.attachments = []

    // TODO: reformat the string sent to the LLM
    let messageContent = ChatMessageContent.text(ChatMessageTextContent(
      projectRoot: projectInfo?.dirPath,
      text: textInput.string.string,
      attachments: attachments))
    let userMessage = ChatMessage(
      content: [messageContent],
      role: .user)

    events.append(.message(.init(content: messageContent, role: .user)))
    messages.append(userMessage)

    // Send the message to the server and stream the response.
    do {
      let tools: [any Tool] = toolsPlugin.tools(for: input.mode)
      streamingTask = Task {
        async let done = llmService.sendMessage(
          messageHistory: messages.apiFormat,
          tools: tools,
          model: selectedModel,
          context: DefaultChatContext(
            project: projectInfo?.path,
            projectRoot: projectInfo?.dirPath,
            prepareForWriteToolUse: { [weak self] in await self?.handlePrepareForWriteToolUse() },
            requestToolApproval: { [weak self] toolUse in
              try await self?.handleToolApproval(for: toolUse)
            },
            chatMode: input.mode),
          handleUpdateStream: { newMessages in
            Task { @MainActor [weak self] in
              guard let self else { return }
              var trackedMessages = Set<UUID>()
              for await update in newMessages.updates {
                for newMessage in update.filter({ !trackedMessages.contains($0.id) }) {
                  trackedMessages.insert(newMessage.id)

                  let newMessageState = ChatMessage(
                    content: newMessage.content.map { $0.domainFormat(projectRoot: projectInfo?.dirPath) },
                    role: .assistant)
                  messages.append(newMessageState)

                  for await update in newMessage.updates {
                    // new message content was received
                    if let newContent = update.content.last {
                      var content = newMessageState.content
                      let newContent = newContent.domainFormat(projectRoot: projectInfo?.dirPath)
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
      defaultLogger.error("Error sending message", error)
      streamingTask = nil

      if case .message(let lastEvent) = events.last {
        events[events.count - 1] = .message(lastEvent.with(failureReason: "Error sending message: \(error.localizedDescription)"))
      }
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

  private static let userDefaultsAlwaysApproveKey = "alwaysApprove_"

  @ObservationIgnored private var workspaceRootObservation: AnyCancellable?

  @ObservationIgnored
  @Dependency(\.toolsPlugin) private var toolsPlugin: ToolsPlugin

  @MainActor @ObservationIgnored @Dependency(\.llmService) private var llmService: LLMService

  @ObservationIgnored
  @Dependency(\.xcodeObserver) private var xcodeObserver

  @ObservationIgnored
  @Dependency(\.fileManager) private var fileManager: FileManagerI

  @ObservationIgnored @Dependency(\.userDefaults) private var userDefaults

  @ObservationIgnored
  @Dependency(\.checkpointService) private var checkpointService: CheckpointService
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()

  private var streamingTask: Task<Void, any Error>? = nil {
    didSet {
      isStreamingResponse = streamingTask != nil
    }
  }

  private func handleToolApproval(for toolUse: any ToolUse) async throws {
    // Check if user has already approved this tool type
    if shouldAlwaysApprove(toolName: toolUse.toolName) {
      return // Skip approval for this tool
    }

    let approvalResult = await input.requestApproval(
      for: toolUse)

    switch approvalResult {
    case .denied:
      throw LLMServiceError.toolUsageDenied
    case .approved:
      break // Continue execution
    case .alwaysApprove(let toolName):
      // Store preference and continue
      storeAlwaysApprovePreference(for: toolName)
    case .cancelled:
      throw CancellationError()
    }
  }

  private func handlePrepareForWriteToolUse() async {
    guard let projectInfo = updateProjectInfo() else {
      return
    }
    do {
      // Create checkpoint and add it to events before the tool call is executed.
      let checkpoint = try await checkpointService.createCheckpoint(
        projectRoot: projectInfo.dirPath,
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
      defaultLogger.error("Failed to create checkpoint", error)
    }
  }

  private func storeAlwaysApprovePreference(for toolName: String) {
    userDefaults.set(true, forKey: "\(Self.userDefaultsAlwaysApproveKey)\(toolName)")
  }

  private func shouldAlwaysApprove(toolName: String) -> Bool {
    userDefaults.bool(forKey: "\(Self.userDefaultsAlwaysApproveKey)\(toolName)")
  }

  private func updateProjectInfo() -> SelectedProjectInfo? {
    if let projectInfo {
      return projectInfo
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
      let projectInfo = SelectedProjectInfo(path: workspace.url, dirPath: projectRoot)
      self.projectInfo = projectInfo
      return projectInfo
    }
    return nil
  }

}

// MARK: - DefaultChatContext

struct DefaultChatContext: ChatContext {

  init(
    project: URL?,
    projectRoot: URL?,
    prepareForWriteToolUse: @escaping @Sendable () async -> Void,
    requestToolApproval: @escaping @Sendable (any ToolUse) async throws -> Void,
    chatMode: ChatMode)
  {
    self.project = project
    self.projectRoot = projectRoot
    self.prepareForWriteToolUse = prepareForWriteToolUse
    self.requestToolApproval = requestToolApproval
    self.chatMode = chatMode
  }

  let project: URL?
  let projectRoot: URL?
  let prepareForWriteToolUse: @Sendable () async -> Void
  let requestToolApproval: @Sendable (any ToolUse) async throws -> Void
  let chatMode: ChatMode
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
