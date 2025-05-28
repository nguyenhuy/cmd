// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import SettingsServiceInterface
import SwiftUI

#if DEBUG

// MARK: - Helper for Providers Previews

extension MockSettingsService {
  fileprivate convenience init(
    forProviders anthropicAPIKey: String? = nil,
    openAIAPIKey: String? = nil,
    openRouterAPIKey: String? = nil,
    googleAIAPIKey: String? = nil,
    cohereAPIKey: String? = nil)
  {
    self.init(.init(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: anthropicAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      openAISettings: openAIAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      openRouterSettings: openRouterAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      googleAISettings: googleAIAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      cohereSettings: cohereAPIKey.map { .init(apiKey: $0, baseUrl: nil) }))
  }
}

#Preview("Providers - Empty State") {
  withDependencies({
    $0.settingsService = MockSettingsService(forProviders: nil, openAIAPIKey: nil)
  }) {
    ProvidersView(providerSettings: .constant([]))
      .frame(width: 600, height: 400)
      .padding()
  }
}

#Preview("Providers - Single Provider") {
  withDependencies({
    $0.settingsService = MockSettingsService(forProviders: "test", openAIAPIKey: nil)
  }) {
    ProvidersView(providerSettings: .constant([
      .anthropic(.init(apiKey: "sk-ant-api03-...")),
    ]))
    .frame(width: 600, height: 400)
    .padding()
  }
}

#Preview("Providers - Multiple Providers") {
  withDependencies({
    $0.settingsService = MockSettingsService(
      forProviders: "sk-ant-api03-...",
      openAIAPIKey: "sk-...",
      googleAIAPIKey: "AIza...")
  }) {
    ProvidersView(providerSettings: .constant([
      .anthropic(.init(apiKey: "sk-ant-api03-...")),
      .openAI(.init(apiKey: "sk-...")),
    ]))
    .frame(width: 600, height: 500)
    .padding()
  }
}

#endif
