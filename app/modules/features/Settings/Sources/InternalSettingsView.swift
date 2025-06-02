// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import FoundationInterfaces
import SwiftUI

struct InternalSettingsView: View {
  @Binding var repeatLastLLMInteraction: Bool
  @Binding var showOnboardingScreenAgain: Bool
  @Binding var pointReleaseXcodeExtensionToDebugApp: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 16) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Repeat last LLM interaction")
            Text("Enable for debugging LLM responses")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Toggle("", isOn: $repeatLastLLMInteraction)
            .toggleStyle(.switch)
        }

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Show onboarding again")
            Text("Show onboarding flow at next app launch")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Toggle("", isOn: $showOnboardingScreenAgain)
            .toggleStyle(.switch)
        }

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Point Release Xcode Extension to Debug App")
            Text("Use the debug version of the extension for development")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Toggle("", isOn: $pointReleaseXcodeExtensionToDebugApp)
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

  @Dependency(\.userDefaults) private var userDefaults

}
