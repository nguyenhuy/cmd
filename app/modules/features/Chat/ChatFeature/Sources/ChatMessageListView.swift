// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import CheckpointServiceInterface
import DLS
import SwiftUI

// MARK: - ChatMessageList

struct ChatMessageList: View {
  #if DEBUG
  /// Initializer for previews
  init(
    events: [ChatEvent],
    onRestoreTapped: ((Checkpoint) -> Void)? = nil)
  {
    self.events = events
    self.onRestoreTapped = onRestoreTapped
  }
  #endif

  init(viewModel: ChatTabViewModel) {
    events = viewModel.events
    onRestoreTapped = { [weak viewModel] checkpoint in
      viewModel?.handleRestore(checkpoint: checkpoint)
    }
  }

  var body: some View {
    ScrollView {
      AppUpdateWidget()
      LazyVStack(spacing: 0) {
        ForEach(events) { event in
          switch event {
          case .message(let message):
            ChatMessageView(message: message)
          case .checkpoint(let checkpoint):
            CheckpointView(checkpoint: checkpoint, onRestoreTapped: onRestoreTapped)
          }
        }
      }
      .padding()
    }
  }

  private let events: [ChatEvent]
  private let onRestoreTapped: ((Checkpoint) -> Void)?
}
