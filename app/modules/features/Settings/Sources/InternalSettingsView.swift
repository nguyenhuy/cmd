// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import FoundationInterfaces
import SwiftUI

struct InternalSettingsView: View {
  @Binding var repeatLastLLMInteraction: Bool
  @Binding var showOnboardingScreenAgain: Bool
  @Binding var pointReleaseXcodeExtensionToDebugApp: Bool
  @Binding var showCheckForUpdateButton: Bool
  @Binding var showInternalSettingsInRelease: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 16) {
        row("Show internal settings in Debug app", value: $showInternalSettingsInRelease)
        row("Repeat last LLM interaction", caption: "Enable for debugging LLM responses", value: $repeatLastLLMInteraction)
        row("Show onboarding again", caption: "Show onboarding flow at next app launch", value: $showOnboardingScreenAgain)
        row(
          "Point Release Xcode Extension to Debug App",
          caption: "Use the debug version of the extension for development",
          value: $pointReleaseXcodeExtensionToDebugApp)
        row("Show update button (wip)", value: $showCheckForUpdateButton)
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

  @ViewBuilder
  private func row(_ text: String, caption: String? = nil, value: Binding<Bool>) -> some View {
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
      Toggle("", isOn: value)
        .toggleStyle(.switch)
    }
  }

}
