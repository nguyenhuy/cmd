// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import DLS
import SwiftUI

struct AppUpdateBanner: View {
  init(
    appUpdateInfo: AppUpdateInfo?,
    onRelaunchTapped: @escaping () -> Void,
    onIgnoreTapped: @escaping () -> Void)
  {
    self.appUpdateInfo = appUpdateInfo
    self.onRelaunchTapped = onRelaunchTapped
    self.onIgnoreTapped = onIgnoreTapped
    currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }

  var body: some View {
    if hasIgnoredUpdate {
      EmptyView()
    } else {
      VStack(alignment: .leading) {
        HStack {
          Text("Update available")
            .font(.headline)
            .padding(.bottom, 2)
          Spacer()
          IconButton(action: {
            onIgnoreTapped()
            hasIgnoredUpdate = true
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

  @State private var hasIgnoredUpdate = false
  @Environment(\.colorScheme) private var colorScheme

  private let appUpdateInfo: AppUpdateInfo?
  private let onRelaunchTapped: () -> Void
  private let onIgnoreTapped: () -> Void
  private let currentAppVersion: String?

}
