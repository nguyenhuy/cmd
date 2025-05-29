// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import Dependencies
import Foundation
import LLMFoundation
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

    providerSettings = settings.llmProviderSettings

    settingsService.liveValues()
      .receive(on: RunLoop.main)
      .sink { [weak self] newSettings in
        self?.settings = newSettings
      }
      .store(in: &cancellables)
  }

  var settings: SettingsServiceInterface.Settings

  // MARK: - Initialization

  var providerSettings: AllLLMProviderSettings {
    didSet {
      settings.llmProviderSettings = providerSettings
      save()
    }
  }

  func save() {
    settingsService.update(to: settings)
  }

  private var cancellables = Set<AnyCancellable>()

  private let settingsService: SettingsService
}

typealias AllLLMProviderSettings = [LLMProvider: LLMProviderSettings]
extension AllLLMProviderSettings {
  var nextCreatedOrder: Int {
    values.map(\.createdOrder).max() ?? 0 + 1
  }
}
