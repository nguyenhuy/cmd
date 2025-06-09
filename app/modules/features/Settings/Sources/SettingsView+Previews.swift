// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies
import SettingsServiceInterface
import SwiftUI

#if DEBUG

extension LLMProviderSettings {
  init(apiKey: String, baseUrl: String? = nil) {
    self.init(apiKey: apiKey, baseUrl: baseUrl, createdOrder: 0)
  }
}

extension MockSettingsService {
  convenience init(
    pointReleaseXcodeExtensionToDebugApp: Bool = false,
    anthropicAPIKey: String? = nil,
    openAIAPIKey: String? = nil,
    openRouterAPIKey: String? = nil)
  {
    self.init(.init(
      pointReleaseXcodeExtensionToDebugApp: pointReleaseXcodeExtensionToDebugApp,
      llmProviderSettings: [
        .anthropic: anthropicAPIKey.map { .init(apiKey: $0, baseUrl: nil, createdOrder: 0) },
        .openAI: openAIAPIKey.map { .init(apiKey: $0, baseUrl: nil, createdOrder: 1) },
        .openRouter: openRouterAPIKey.map { .init(apiKey: $0, baseUrl: nil, createdOrder: 2) },
      ].compactMapValues { $0 }))
  }
}

// MARK: - Main Settings Previews

#Preview("Settings - Landing") {
  withDependencies({
    $0.settingsService = MockSettingsService(anthropicAPIKey: "test")
  }) {
    SettingsView(viewModel: SettingsViewModel())
      .frame(width: 600, height: 500)
  }
}

#Preview("Settings - Empty State") {
  withDependencies({
    $0.settingsService = MockSettingsService(pointReleaseXcodeExtensionToDebugApp: false)
  }) {
    SettingsView(viewModel: SettingsViewModel())
      .frame(width: 600, height: 500)
  }
}

#Preview("Settings - Multiple Providers") {
  withDependencies({
    $0.settingsService = MockSettingsService(
      pointReleaseXcodeExtensionToDebugApp: true,
      anthropicAPIKey: "test-anthropic",
      openAIAPIKey: "test-openai")
  }) {
    SettingsView(viewModel: SettingsViewModel())
      .frame(width: 600, height: 500)
  }
}

#endif
