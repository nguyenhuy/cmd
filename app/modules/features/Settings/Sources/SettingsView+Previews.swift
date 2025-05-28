// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import SettingsServiceInterface
import SwiftUI

#if DEBUG

extension MockSettingsService {
  convenience init(
    pointReleaseXcodeExtensionToDebugApp: Bool = false,
    anthropicAPIKey: String? = nil,
    openAIAPIKey: String? = nil,
    openRouterAPIKey: String? = nil,
    googleAIAPIKey: String? = nil,
    cohereAPIKey: String? = nil)
  {
    self.init(.init(
      pointReleaseXcodeExtensionToDebugApp: pointReleaseXcodeExtensionToDebugApp,
      anthropicSettings: anthropicAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      openAISettings: openAIAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      openRouterSettings: openRouterAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      googleAISettings: googleAIAPIKey.map { .init(apiKey: $0, baseUrl: nil) },
      cohereSettings: cohereAPIKey.map { .init(apiKey: $0, baseUrl: nil) }))
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
      openAIAPIKey: "test-openai",
      googleAIAPIKey: "test-googleai")
  }) {
    SettingsView(viewModel: SettingsViewModel())
      .frame(width: 600, height: 500)
  }
}

#endif
