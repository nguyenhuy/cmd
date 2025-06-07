// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFeatureInterface

#if DEBUG
public final class MockChatHistoryService: ChatHistoryService {

  public func save(chatThread _: ChatThreadModel) async throws {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadLastChatThreads(last _: Int) async throws -> [ChatThreadModelMetadata] {
    fatalError("Not implemented in MockChatHistoryService")
  }

  public func loadChatThread(id _: String) async throws -> ChatThreadModel? {
    fatalError("Not implemented in MockChatHistoryService")
  }

}
#endif
