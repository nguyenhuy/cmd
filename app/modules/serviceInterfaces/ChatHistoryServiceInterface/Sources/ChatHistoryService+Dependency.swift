// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - ChatHistoryServiceProviding

public protocol ChatHistoryServiceProviding {
  var chatHistoryService: ChatHistoryService { get }
}

// MARK: - ChatHistoryServiceDependencyKey

public final class ChatHistoryServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: ChatHistoryService = MockChatHistoryService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: ChatHistoryService = () as! ChatHistoryService
  #endif
}

extension DependencyValues {
  public var chatHistoryService: ChatHistoryService {
    get { self[ChatHistoryServiceDependencyKey.self] }
    set { self[ChatHistoryServiceDependencyKey.self] = newValue }
  }
}
