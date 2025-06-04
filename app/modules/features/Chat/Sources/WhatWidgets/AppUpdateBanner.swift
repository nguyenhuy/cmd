// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import DLS
import SwiftUI

struct AppUpdateBanner: View {
  init(
    appUpdateInfo: AppUpdateInfo?,
    onRelaunchTapped: @escaping () -> Void,
    onSkipTapped: @escaping () -> Void)
  {
    self.appUpdateInfo = appUpdateInfo
    self.onRelaunchTapped = onRelaunchTapped
    self.onSkipTapped = onSkipTapped
    currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }

  var body: some View {
    if hasSkippedUpdate {
      EmptyView()
    } else {
      VStack(alignment: .leading) {
        HStack {
          Text("Update available")
            .font(.headline)
            .padding(.bottom, 2)
          Spacer()
          IconButton(action: {
            onSkipTapped()
            hasSkippedUpdate = true
          }, systemName: "xmark")
            .frame(width: 12, height: 12)
        }
        if let appUpdateInfo {
          Text("Version: \(appUpdateInfo.version) is now available.")
          if let currentAppVersion {
            Text("Current: \(currentAppVersion)")
              .font(.caption)
          }
        }
        if let releaseNotesURL = appUpdateInfo?.releaseNotesURL {
          Link("Release Notes", destination: releaseNotesURL)
        }
        HoveredButton(
          action: {
            onRelaunchTapped()
          },
          onHoverColor: colorScheme.tertiarySystemBackground,
          backgroundColor: colorScheme.secondarySystemBackground,
          padding: 5,
          content: {
            Text("Relaunch")
          })
          .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .roundedCornerWithBorder(borderColor: colorScheme.textAreaBorderColor, radius: 6)
    }
  }

  @State private var hasSkippedUpdate = false
  @Environment(\.colorScheme) private var colorScheme

  private let appUpdateInfo: AppUpdateInfo?
  private let onRelaunchTapped: () -> Void
  private let onSkipTapped: () -> Void
  private let currentAppVersion: String?

}
