// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import ConcurrencyFoundation

// MARK: - Settings

public struct Settings: Sendable, Codable, Equatable {
  #if DEBUG
  public init(
    pointReleaseXcodeExtensionToDebugApp: Bool,
    allowAnonymousAnalytics: Bool = false,
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
  }

  public struct LLMProviderSettings: Sendable, Codable, Equatable {
    public var apiKey: String
    public var baseUrl: String?

    public init(
      apiKey: String,
      baseUrl: String?)
    {
      self.apiKey = apiKey
      self.baseUrl = baseUrl
    }
  }

  public var allowAnonymousAnalytics: Bool
  public var pointReleaseXcodeExtensionToDebugApp: Bool
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

}

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
