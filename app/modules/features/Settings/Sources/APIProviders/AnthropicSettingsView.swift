// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - AnthropicSettingsView

struct AnthropicSettingsView: View {
  @Binding var settings: AnthropicProviderSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Anthropic API Key")

      if showValue {
        TextField("API Key", text: $settings.apiKey)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      } else {
        SecureField("API Key", text: $settings.apiKey)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }
      if !settings.apiKey.isEmpty {
        Button(action: {
          showValue.toggle()
        }) {
          Text(showValue ? "Hide" : "Show")
            .font(.footnote)
            .padding(3)
            .padding(.leading, 5)
            .tappableTransparentBackground()
        }
        .buttonStyle(.plain)
        .acceptClickThrough()
      }
    }
    .padding(.vertical, 10)
  }

  @State private var showValue = false

}

#if DEBUG
#Preview("Anthropic Settings - Empty") {
  AnthropicSettingsView(settings: .constant(.init(apiKey: "")))
}

#Preview("Anthropic Settings - With API key") {
  AnthropicSettingsView(settings: .constant(.init(apiKey: "foo")))
}
#endif
