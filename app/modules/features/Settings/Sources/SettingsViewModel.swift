// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import Dependencies
import Foundation
import SettingsServiceInterface
import SwiftUI

// MARK: - SettingsViewModel

@Observable
@MainActor
public final class SettingsViewModel {
  public init() {
    @Dependency(\.settingsService) var settingsService
    self.settingsService = settingsService
    let settings = settingsService.values()
    self.settings = settings

    providerSettings = [
      settings.anthropicSettings.map { ProviderSettings.anthropic(.init(apiKey: $0.apiKey, apiUrl: $0.apiUrl)) },
      settings.openAISettings.map { ProviderSettings.openAI(.init(apiKey: $0.apiKey)) },
    ].compactMap(\.self)

    settingsService.liveValues()
      .receive(on: RunLoop.main)
      .sink { [weak self] newSettings in
        self?.settings = newSettings
      }
      .store(in: &cancellables)
  }

  var settings: SettingsServiceInterface.Settings

  // MARK: - Initialization

  var providerSettings: [ProviderSettings] {
    didSet {
      var newSettings = settings
      newSettings.anthropicSettings = nil
      newSettings.openAISettings = nil
      for providerSetting in providerSettings {
        switch providerSetting {
        case .anthropic(let settings):
          newSettings.anthropicSettings = .init(apiKey: settings.apiKey, apiUrl: settings.apiUrl)
        case .openAI(let settings):
          newSettings.openAISettings = .init(apiKey: settings.apiKey, apiUrl: nil)
        }
      }
      settings = newSettings
    }
  }

  func save() {
    settingsService.update(to: settings)
  }

  private var cancellables = Set<AnyCancellable>()

  private let settingsService: SettingsService
}
