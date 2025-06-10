// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import ChatHistoryServiceInterface
import Dependencies
import SwiftUI

#if DEBUG

let date = Date()

#Preview {
  withDependencies {
    $0.chatHistoryService = MockChatHistoryService(
      chatThreads: [
        .init(
          id: UUID(),
          name: "last thread",
          messages: [],
          events: [],
          projectInfo: nil,
          createdAt: Date(timeInterval: -1, since: date)),
        .init(
          id: UUID(),
          name: "other thread",
          messages: [],
          events: [],
          projectInfo: nil,
          createdAt: Date(timeInterval: -2, since: date)),
      ]
        + Array(repeating: 0, count: 100).indices.map { i in
          .init(
            id: UUID(),
            name: "other thread # \(i)",
            messages: [],
            events: [],
            projectInfo: nil,
            createdAt: Date(timeInterval: TimeInterval(-2 - i * 3600 * 3), since: date))
        })
  } operation: {
    ChatHistoryView(
      viewModel: ChatHistoryViewModel(),
      onBack: { },
      onSelectThread: { _ in })
      .frame(width: 400, height: 600)
  }
}
#endif
