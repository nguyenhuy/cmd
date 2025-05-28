// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import LLMFoundation

// MARK: - Settings

public struct Settings: Sendable, Equatable {
  public init(
    pointReleaseXcodeExtensionToDebugApp: Bool,
    allowAnonymousAnalytics: Bool = false,
<<<<<<< HEAD
    preferedProviders: [LLMModel: LLMProvider] = [:],
    llmProviderSettings: [LLMProvider: LLMProviderSettings] = [:],
    inactiveModels: [LLMModel] = [])
  {
    self.pointReleaseXcodeExtensionToDebugApp = pointReleaseXcodeExtensionToDebugApp
    self.allowAnonymousAnalytics = allowAnonymousAnalytics
    self.preferedProviders = preferedProviders
    self.llmProviderSettings = llmProviderSettings
    self.inactiveModels = inactiveModels
=======
    anthropicSettings: LLMProviderSettings?,
    openAISettings: LLMProviderSettings?,
    openRouterSettings: LLMProviderSettings? = nil,
    googleAISettings _: LLMProviderSettings? = nil,
    cohereSettings _: LLMProviderSettings? = nil)
  {
    self.pointReleaseXcodeExtensionToDebugApp = pointReleaseXcodeExtensionToDebugApp
    self.allowAnonymousAnalytics = allowAnonymousAnalytics
    self.anthropicSettings = anthropicSettings
    self.openAISettings = openAISettings
    self.openRouterSettings = openRouterSettings
  }
  #endif

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pointReleaseXcodeExtensionToDebugApp = try container.decodeIfPresent(
      Bool.self,
      forKey: .pointReleaseXcodeExtensionToDebugApp) ?? false
    #if DEBUG
    allowAnonymousAnalytics = try container.decodeIfPresent(Bool.self, forKey: .allowAnonymousAnalytics) ?? true
    #else
    allowAnonymousAnalytics = try container.decodeIfPresent(Bool.self, forKey: .allowAnonymousAnalytics) ?? false
    #endif
    allowAnonymousAnalytics = try container.decodeIfPresent(Bool.self, forKey: .allowAnonymousAnalytics) ?? true
    anthropicSettings = try container.decodeIfPresent(Settings.LLMProviderSettings.self, forKey: .anthropicSettings)
    openAISettings = try container.decodeIfPresent(Settings.LLMProviderSettings.self, forKey: .openAISettings)
    openRouterSettings = try container.decodeIfPresent(Settings.LLMProviderSettings.self, forKey: .openRouterSettings)
>>>>>>> 9cca109 (fix remaining tests)
  }

  public struct LLMProviderSettings: Sendable, Codable, Equatable {
    /// To help keep track of which Provider was setup first, we use an incrementing order.
    /// This order can be useful for determining which provider to default to when multiple are available.
    public let createdOrder: Int
    public var apiKey: String
    public var baseUrl: String?

    public init(
      apiKey: String,
      baseUrl: String?,
      createdOrder: Int)
    {
      self.apiKey = apiKey
      self.baseUrl = baseUrl
      self.createdOrder = createdOrder
    }
  }

  public var allowAnonymousAnalytics: Bool
  public var pointReleaseXcodeExtensionToDebugApp: Bool
<<<<<<< HEAD
  // LLM settings
  public var preferedProviders: [LLMModel: LLMProvider]
  public var llmProviderSettings: [LLMProvider: LLMProviderSettings]

  public var inactiveModels: [LLMModel]
=======
  public var anthropicSettings: LLMProviderSettings?
  public var openAISettings: LLMProviderSettings?
  public var openRouterSettings: LLMProviderSettings?

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(pointReleaseXcodeExtensionToDebugApp, forKey: .pointReleaseXcodeExtensionToDebugApp)
    try container.encode(allowAnonymousAnalytics, forKey: .allowAnonymousAnalytics)
    try container.encodeIfPresent(anthropicSettings, forKey: .anthropicSettings)
    try container.encodeIfPresent(openAISettings, forKey: .openAISettings)
    try container.encodeIfPresent(openRouterSettings, forKey: .openRouterSettings)
  }

  private enum CodingKeys: String, CodingKey {
    case pointReleaseXcodeExtensionToDebugApp
    case allowAnonymousAnalytics
    case anthropicSettings
    case openAISettings
    case openRouterSettings
  }
>>>>>>> 9cca109 (fix remaining tests)

}

public typealias LLMProviderSettings = Settings.LLMProviderSettings

// MARK: - SettingsService

public protocol SettingsService: Sendable {
  /// Get the current value of a setting.
  func value<T: Equatable>(for keypath: KeyPath<Settings, T>) -> T
  /// Get the current value of a setting as a live value.
  func liveValue<T: Equatable>(for keypath: KeyPath<Settings, T>) -> ReadonlyCurrentValueSubject<T, Never>

  /// Get all settings.
  func values() -> Settings

  /// Get all settings as a live value.
  func liveValues() -> ReadonlyCurrentValueSubject<Settings, Never>

  /// Update the value of a setting
  func update<T: Equatable>(setting: WritableKeyPath<Settings, T>, to value: T)

  /// Update the value of a setting
  func update(to settings: Settings)

  /// Reset a setting to its default value
  func resetToDefault(setting: WritableKeyPath<Settings, some Equatable>)

  /// Reset all settings to their default values
  func resetAllToDefault()
}

// MARK: - SettingsServiceProviding

public protocol SettingsServiceProviding {
  var settingsService: SettingsService { get }
}
