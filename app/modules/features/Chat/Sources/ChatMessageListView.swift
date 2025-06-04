// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import CheckpointServiceInterface
import CodePreview
import ConcurrencyFoundation
import Dependencies
import DLS
import FoundationInterfaces
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
      if
        case .updateAvailable(let appUpdateInfo) = appUpdateService.hasUpdateAvailable.currentValue,
        !appUpdateService.isUpdateIgnored(appUpdateInfo)
      {
        AppUpdateBanner(
          appUpdateInfo: appUpdateInfo,
          onRelaunchTapped: { appUpdateService.relaunch() },
          onIgnoreTapped: { appUpdateService.ignore(update: appUpdateInfo) })
      }
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

  @Dependency(\.appUpdateService) private var appUpdateService
  private let events: [ChatEvent]
  private let onRestoreTapped: ((Checkpoint) -> Void)?
}
