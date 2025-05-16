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
    openAIAPIKey: String? = nil)
  {
    self.init(.init(
      pointReleaseXcodeExtensionToDebugApp: pointReleaseXcodeExtensionToDebugApp,
      anthropicSettings: anthropicAPIKey.map { .init(apiKey: $0, apiUrl: nil) },
      openAISettings: openAIAPIKey.map { .init(apiKey: $0, apiUrl: nil) }))
  }
}

// MARK: - Previews

#Preview("Settings - General Tab") {
  withDependencies({
    $0.settingsService = MockSettingsService(anthropicAPIKey: "test")
  }) {
    SettingsView(viewModel: SettingsViewModel())
  }
}

// #Preview("Settings - Advanced Tab") {
//  SettingsView(viewModel: PreviewSettingsViewModel.createMock())
//    .onAppear {
//      // Set the selected tab to Advanced
//      // Note: This doesn't work in previews because the onAppear happens after the preview renders
//      // But it's here to show how you would do it in a real app
//    }
// }
//
// #Preview("Settings - No Accounts") {
//  SettingsView(viewModel: PreviewSettingsViewModel.createMock(withActiveAccounts: false))
// }
//
// #Preview("Settings - Dark Mode") {
//  SettingsView(viewModel: PreviewSettingsViewModel.createMock())
//    .preferredColorScheme(.dark)
// }

#endif
