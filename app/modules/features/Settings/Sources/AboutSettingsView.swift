// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - AboutSettingsView

struct AboutSettingsView: View {
  @Binding var allowAnonymousAnalytics: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // App Info Section
      VStack(alignment: .leading, spacing: 16) {
        Text("App Information")
          .font(.headline)

        VStack(alignment: .leading, spacing: 12) {
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
