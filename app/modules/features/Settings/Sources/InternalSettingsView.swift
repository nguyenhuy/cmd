// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

struct InternalSettingsView: View {
  @Binding var pointReleaseXcodeExtensionToDebugApp: Bool
  @Binding var allowAnonymousAnalytics: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 16) {
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

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Repeat last LLM interaction")
            Text("Enable for debugging LLM responses")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Toggle("", isOn: Binding<Bool>(
            get: {
              UserDefaults.standard.bool(forKey: "llmService.isRepeating")
            },
            set: { value in
              UserDefaults.standard.set(value, forKey: "llmService.isRepeating")
            }
          ))
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
  }
}
