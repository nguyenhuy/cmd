// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ThreadSafe

#if DEBUG
public final class MockChatHistoryService: ChatHistoryService {
  public func setup() async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveChatTab(_: ChatTabModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadChatTabs() async throws -> [ChatTabModel] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func deleteChatTab(id _: String) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveChatMessage(_: ChatMessageModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadChatMessages(for _: String) async throws -> [ChatMessageModel] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveChatMessageContent(_: ChatMessageContentModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func updateChatMessageContent(_: ChatMessageContentModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadChatMessageContents(for _: String) async throws -> [ChatMessageContentModel] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveAttachment(_: AttachmentModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadAttachments(for _: String) async throws -> [AttachmentModel] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveChatEvent(_: ChatEventModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadChatEvents(for _: String) async throws -> [ChatEventModel] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func saveChatTabAtomic(
    tab _: ChatTabModel,
    newMessages _: [ChatMessageModel],
    messageContents _: [ChatMessageContentModel],
    attachments _: [AttachmentModel],
    newEvents _: [ChatEventModel])
    async throws
  {
    fatalError("Not implemented in MockChatHistoryService")
  }

}
#endif
