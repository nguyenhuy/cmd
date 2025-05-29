// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import SettingsServiceInterface
import SwiftUI

#if DEBUG

// MARK: - Helper for Providers Previews

#Preview("Providers - Empty State") {
  withDependencies({
    $0.settingsService = MockSettingsService(anthropicAPIKey: nil, openAIAPIKey: nil)
  }) {
    ProvidersView(providerSettings: .constant([:]))
      .frame(width: 600, height: 400)
      .padding()
  }
}

#Preview("Providers - Single Provider") {
  withDependencies({
    $0.settingsService = MockSettingsService(anthropicAPIKey: "test", openAIAPIKey: nil)
  }) {
    ProvidersView(providerSettings: .constant([
      .anthropic: .init(apiKey: "sk-ant-api03-..."),
    ]))
    .frame(width: 600, height: 400)
    .padding()
  }
}

#Preview("Providers - Multiple Providers") {
  withDependencies({
    $0.settingsService = MockSettingsService(
      anthropicAPIKey: "sk-ant-api03-...",
      openAIAPIKey: "sk-...")
  }) {
    ProvidersView(providerSettings: .constant([
      .anthropic: .init(apiKey: "sk-ant-api03-..."),
      .openAI: .init(apiKey: "sk-..."),
    ]))
    .frame(width: 600, height: 500)
    .padding()
  }
}

#endif
