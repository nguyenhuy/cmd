// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CheckpointServiceInterface
import CodePreview
import ConcurrencyFoundation
import Dependencies
import DLS
import FoundationInterfaces
import SwiftUI

// MARK: - ChatMessageList

struct ChatMessageList: View {
  init(events: [ChatEvent], onRestoreTapped: ((Checkpoint) -> Void)? = nil) {
    self.events = events
    self.onRestoreTapped = onRestoreTapped
  }

  let events: [ChatEvent]
  let onRestoreTapped: ((Checkpoint) -> Void)?

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 6) {
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

}
