// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import Dependencies
import DLS
import SwiftUI

// MARK: - AboutSettingsView

struct AboutSettingsView: View {
  @Binding var allowAnonymousAnalytics: Bool
  @Binding var automaticallyCheckForUpdates: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // App Info Section
      VStack(alignment: .leading, spacing: 16) {
        Text("App Information")
          .font(.headline)

        VStack(alignment: .leading, spacing: 12) {
          if case .updateAvailable(let appUpdateInfo) = appUpdateService.hasUpdateAvailable.currentValue {
            AppUpdateRow(
              appUpdateInfo: appUpdateInfo,
              onRelaunchTapped: { appUpdateService.relaunch() })
            Divider()
          }
          InfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
          InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
          InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1))
      }

      // Privacy Section
      VStack(alignment: .leading, spacing: 16) {
        Text("Privacy")
          .font(.headline)

        VStack(spacing: 16) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Allow anonymous error and usage reporting")
              Text(
                "Help improve command by sending anonymous usage data and error reports. No code, prompts, or personal information is ever sent.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $allowAnonymousAnalytics)
              .toggleStyle(.switch)
          }

          Divider()

          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Automatically check for updates")
              Text("Automatically download and install updates in the background when available.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $automaticallyCheckForUpdates)
              .toggleStyle(.switch)
          }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1))
      }

      Spacer()
    }
  }

  @Dependency(\.appUpdateService) private var appUpdateService: AppUpdateService

}

// MARK: - InfoRow

private struct InfoRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .fontWeight(.medium)
    }
  }
}

// MARK: - AppUpdateRow

struct AppUpdateRow: View {
  init(
    appUpdateInfo: AppUpdateInfo?,
    onRelaunchTapped: @escaping () -> Void)
  {
    self.appUpdateInfo = appUpdateInfo
    self.onRelaunchTapped = onRelaunchTapped
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("Update \(versionInfo)available")
          .font(.headline)
          .padding(.bottom, 2)
        if let releaseNotesURL = appUpdateInfo?.releaseNotesURL {
          Link("Release Notes", destination: releaseNotesURL)
        }
      }
      Spacer()
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
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  private let appUpdateInfo: AppUpdateInfo?
  private let onRelaunchTapped: () -> Void

  private var versionInfo: String {
    if let version = appUpdateInfo?.version {
      "\(version) "
    } else {
      ""
    }
  }

}
