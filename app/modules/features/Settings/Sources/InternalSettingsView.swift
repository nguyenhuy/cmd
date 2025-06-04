// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import FoundationInterfaces
import SwiftUI

// MARK: - InternalSettingsView

struct InternalSettingsView: View {
  @Binding var repeatLastLLMInteraction: Bool
  @Binding var showOnboardingScreenAgain: Bool
  @Binding var pointReleaseXcodeExtensionToDebugApp: Bool
  @Binding var showCheckForUpdateButton: Bool
  @Binding var showInternalSettingsInRelease: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 16) {
        InternalSettingsRow("Show internal settings in Debug app", value: $showInternalSettingsInRelease)
        InternalSettingsRow(
          "Repeat last LLM interaction",
          caption: "Enable for debugging LLM responses",
          value: $repeatLastLLMInteraction)
        InternalSettingsRow(
          "Show onboarding again",
          caption: "Show onboarding flow at next app launch",
          value: $showOnboardingScreenAgain)
        InternalSettingsRow(
          "Point Release Xcode Extension to Debug App",
          caption: "Use the debug version of the extension for development",
          value: $pointReleaseXcodeExtensionToDebugApp)
        InternalSettingsRow("Show update button (wip)", value: $showCheckForUpdateButton)
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

  @Dependency(\.userDefaults) private var userDefaults
}

// MARK: - InternalSettingsRow

struct InternalSettingsRow: View {
  init(_ text: String, caption: String? = nil, value: Binding<Bool>) {
    self.text = text
    self.caption = caption
    _value = value
  }

  @Binding var value: Bool

  let text: String
  let caption: String?

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(text)
        if let caption {
          Text(caption)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      Spacer()
      Toggle("", isOn: $value)
        .toggleStyle(.switch)
    }
  }
}
