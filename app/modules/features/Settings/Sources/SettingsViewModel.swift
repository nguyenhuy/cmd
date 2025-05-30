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

  /// For each available model, the associated provider.
  var providerForModels: [LLMModel: LLMProvider] {
    get {
      var providerForModels = [LLMModel: LLMProvider]()
      for model in availableModels {
        providerForModels[model] = (try? settings.provider(for: model).0) ?? .anthropic
      }
      for (key, value) in settings.preferedProviders {
        providerForModels[key] = value
      }

      return providerForModels
    }
    set {
      let oldValue = providerForModels
      for (model, provider) in newValue {
        if oldValue[model] != provider {
          settings.preferedProviders[model] = provider
        }
      }
      save()
    }
  }

  var inactiveModels: [LLMModel] {
    get {
      settings.inactiveModels
    }
    set {
      settings.inactiveModels = newValue
      save()
    }
  }

  /// All the models that are available, based on the available providers.
  var availableModels: [LLMModel] {
    settings.availableModels
  }

  /// The LLM providers that have been configured.
  var availableProviders: [LLMProvider] {
    Array(settings.llmProviderSettings.keys)
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
    (values.map(\.createdOrder).max() ?? 0) + 1
  }
}
