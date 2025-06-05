// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import Dependencies
import Foundation
import FoundationInterfaces
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
    @Dependency(\.userDefaults) var userDefaults
    self.userDefaults = userDefaults
    // This one is not dependency injected. That should be ok.
    releaseUserDefaults = try? UserDefaults.releaseShared(bundle: .main)

    let settings = settingsService.values()
    self.settings = settings

    providerSettings = settings.llmProviderSettings
    repeatLastLLMInteraction = userDefaults.bool(forKey: .repeatLastLLMInteraction)
    showOnboardingScreenAgain = !userDefaults.bool(forKey: .hasCompletedOnboardingUserDefaultsKey)
    showInternalSettingsInRelease = releaseUserDefaults?.bool(forKey: .showInternalSettingsInRelease) == true
    defaultChatPositionIsInverted = userDefaults.bool(forKey: .defaultChatPositionIsInverted)

    settingsService.liveValues()
      .receive(on: RunLoop.main)
      .sink { [weak self] newSettings in
        self?.settings = newSettings
      }
      .store(in: &cancellables)
  }

  // MARK: - Initialization

  public var providerSettings: AllLLMProviderSettings {
    didSet {
      settings.llmProviderSettings = providerSettings
      settingsService.update(setting: \.llmProviderSettings, to: providerSettings)
    }
  }

  private(set) var settings: SettingsServiceInterface.Settings

  var allowAnonymousAnalytics: Bool {
    get {
      settings.allowAnonymousAnalytics
    }
    set {
      settings.allowAnonymousAnalytics = newValue
      settingsService.update(setting: \.allowAnonymousAnalytics, to: newValue)
    }
  }

  var automaticallyCheckForUpdates: Bool {
    get {
      settings.automaticallyCheckForUpdates
    }
    set {
      settings.automaticallyCheckForUpdates = newValue
      settingsService.update(setting: \.automaticallyCheckForUpdates, to: newValue)
    }
  }

  // MARK: - Internal settings
  var repeatLastLLMInteraction: Bool {
    didSet {
      userDefaults.set(repeatLastLLMInteraction, forKey: .repeatLastLLMInteraction)
    }
  }

  var showOnboardingScreenAgain: Bool {
    didSet {
      userDefaults.set(!showOnboardingScreenAgain, forKey: .hasCompletedOnboardingUserDefaultsKey)
    }
  }

  var showInternalSettingsInRelease: Bool {
    didSet {
      releaseUserDefaults?.set(showInternalSettingsInRelease, forKey: .showInternalSettingsInRelease)
    }
  }

  var pointReleaseXcodeExtensionToDebugApp: Bool {
    get {
      settings.pointReleaseXcodeExtensionToDebugApp
    }
    set {
      settings.pointReleaseXcodeExtensionToDebugApp = newValue
      settingsService.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: newValue)
    }
  }

  var defaultChatPositionIsInverted: Bool {
    didSet {
      userDefaults.set(defaultChatPositionIsInverted, forKey: .defaultChatPositionIsInverted)
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
      settingsService.update(setting: \.preferedProviders, to: settings.preferedProviders)
    }
  }

  var inactiveModels: [LLMModel] {
    get {
      settings.inactiveModels
    }
    set {
      settings.inactiveModels = newValue
      settingsService.update(setting: \.inactiveModels, to: newValue)
    }
  }

  var customInstructions: SettingsServiceInterface.Settings.CustomInstructions {
    get {
      settings.customInstructions
    }
    set {
      settings.customInstructions = newValue
      settingsService.update(setting: \.customInstructions, to: newValue)
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

  private var cancellables = Set<AnyCancellable>()

  private let settingsService: SettingsService
  private let userDefaults: UserDefaultsI
  private let releaseUserDefaults: UserDefaultsI?

}

public typealias AllLLMProviderSettings = [LLMProvider: LLMProviderSettings]
extension AllLLMProviderSettings {
  var nextCreatedOrder: Int {
    (values.map(\.createdOrder).max() ?? 0) + 1
  }
}
