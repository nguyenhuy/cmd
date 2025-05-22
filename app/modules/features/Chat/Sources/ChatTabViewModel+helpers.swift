// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Dependencies
import Foundation
import JSONFoundation
import LLMServiceInterface
import LoggingServiceInterface
import ServerServiceInterface
import XcodeObserverServiceInterface

extension ChatTabViewModel {

  func createContextMessage(for workspace: XcodeWorkspaceState, projectRoot: URL) async throws -> ChatMessageTextContent {
    // from workspace.url, do a BDS file search
    @Dependency(\.server) var server

    let fullInput = Schema.ListFilesToolInput(
      projectRoot: projectRoot.path,
      path: "",
      recursive: true,
      limit: 200)

    let data = try JSONEncoder().encode(fullInput)
    let response: Schema.ListFilesToolOutput = try await server.postRequest(path: "listFiles", data: data)
    let text = """
      # Current Workspace Directory (\(workspace.url.path) Files:
      \(response.files.filter(\.isFile).map { URL(filePath: $0.path).pathRelative(to: projectRoot) }.joined(separator: "\n"))
      \(response.hasMore ? "(File list truncated. Use list_files on specific subdirectories if you need to explore further)" : "")
      """
    return .init(projectRoot: projectRoot, text: text)
  }
}

// MARK: - State domain to API domain

extension MessageRole {
  var apiFormat: Schema.Message.Role {
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

extension [ChatMessage] {
  /// Converts the content to the API format.
  @MainActor
  var apiFormat: [Schema.Message] {
    flatMap(\.apiFormat)
  }
}

extension ChatMessage {
  /// Converts the content to the API format.
  /// When the content contains a tool use, it will be split across a message from the assistant and a message from the user, hence the array result.
  @MainActor
  fileprivate var apiFormat: [Schema.Message] {
    var messages = [Schema.Message]()
    var currentMessage = Schema.Message(role: role.apiFormat, content: [])
    for (role, messageContent) in content.flatMap(\.apiFormat) {
      if role != currentMessage.role {
        messages.append(currentMessage)
        currentMessage = Schema.Message(role: role ?? self.role.apiFormat, content: [])
      }
      currentMessage = Schema.Message(
        role: currentMessage.role,
        content: currentMessage.content + [messageContent])
    }
    messages.append(currentMessage)
    return messages
  }
}

extension ChatMessageContent {
  /// Converts the content to the API format.
  /// When the content contains a tool use, it will be split across a message from the assistant and a message from the user, hence the array result.
  @MainActor
  fileprivate var apiFormat: [(Schema.Message.Role?, Schema.MessageContent)] {
    switch self {
    case .text(let message):
      return [(nil, .textMessage(.init(
        text: message.text,
        attachments: message.attachments.map(\.apiFormat))))]

    case .nonUserFacingText(let message):
      return [(nil, .textMessage(.init(text: message.text)))]

    case .toolUse(let toolUse):
      do {
        let request = try Schema.MessageContent.toolUseRequest(Schema.ToolUseRequest(
          name: toolUse.toolUse.toolName,
          anyInput: toolUse.toolUse.input,
          id: toolUse.toolUse.toolUseId))

        guard let result = toolUse.toolUse.currentResult else {
          // The tool use has not completed yet.
          // We need to represent a result to be able to continue the conversation.
          // As sending a new message will cancell any in-flight tool use, we represent it as failed due to cancellation.
          return [
            (.assistant, request),
            (.user, .toolResultMessage(.init(
              toolUseId: toolUse.toolUse.toolUseId,
              result: .toolResultFailureMessage(.init(failure: ["error": .string("The tool use has been cancelled.")]))))),
          ]
        }
        let data = try JSONEncoder().encode(result)
        let jsonResult = try JSONDecoder().decode(JSON.Value.self, from: data)
        return [
          (.assistant, request),
          (.user, .toolResultMessage(.init(
            toolUseId: toolUse.toolUse.toolUseId,
            result: .toolResultSuccessMessage(.init(success: jsonResult))))),
        ]
      } catch {
        // Unable to serialize the tool use request.
        defaultLogger.error("Unable to serialize the tool use request.")
        return []
      }
    }
  }
}

extension Attachment {

  fileprivate var apiFormat: Schema.MessageAttachment {
    switch self {
    case .file(let fileAttachment):
      return .fileAttachment(Schema.FileAttachment(
        path: fileAttachment.path.path(),
        content: fileAttachment.content))

    case .image(let imageAttachment):
      return .imageAttachment(Schema.ImageAttachment(url: imageData(from: imageAttachment), mimeType: ""))

    case .fileSelection(let fileSelectionAttachment):
      let startLine = fileSelectionAttachment.startLine
      let endLine = fileSelectionAttachment.endLine
      let content = fileSelectionAttachment.file.content
        .split(separator: "\n", omittingEmptySubsequences: false)
        .dropFirst(startLine - 1)
        .prefix(endLine - startLine + 1)
        .joined(separator: "\n")
      return .fileSelectionAttachment(Schema.FileSelectionAttachment(
        path: fileSelectionAttachment.file.path.path(),
        content: content,
        startLine: fileSelectionAttachment.startLine,
        endLine: fileSelectionAttachment.endLine))

    case .buildError(let buildError):
      return .buildErrorAttachment(Schema.BuildErrorAttachment(
        filePath: buildError.filePath.path(),
        line: buildError.line,
        column: buildError.column,
        message: buildError.message))
    }
  }

  private func imageData(from image: Attachment.ImageAttachment) -> String {
    var mimeType: String?
    if let url = image.path {
      let ext = url.pathExtension
      mimeType = ext == "png" ? "image/png" : ext == "jpg" ? "image/jpeg" : nil
    }
    let data = image.imageData
    return "data:\(mimeType ?? "image/png");base64,\(data.base64EncodedString())"
  }
}

// MARK: - API domain to state domain

extension AssistantMessageContent {
  @MainActor
  func domainFormat(projectRoot: URL?) -> ChatMessageContent {
    switch self {
    case .text(let value):
      let content = ChatMessageTextContent(projectRoot: projectRoot, text: value.content, attachments: [])
      Task {
        for await update in value.updates {
          content.catchUp(deltas: update.deltas)
        }
      }
      return .text(content)

    case .tool(let value):
      let content = ChatMessageToolUseContent(toolUse: value.toolUse)
      return .toolUse(content)
    }
  }
}
