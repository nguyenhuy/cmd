// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import ConcurrencyFoundation

// MARK: - Settings

public struct Settings: Sendable, Codable, Equatable {
  #if DEBUG
  public init(
    pointReleaseXcodeExtensionToDebugApp: Bool,
    enableAnalytics: Bool = false,
    allowAnonymousAnalytics: Bool = true,
    anthropicSettings: AnthropicSettings?,
    openAISettings: OpenAISettings?)
  {
    self.pointReleaseXcodeExtensionToDebugApp = pointReleaseXcodeExtensionToDebugApp
    self.enableAnalytics = enableAnalytics
    self.allowAnonymousAnalytics = allowAnonymousAnalytics
    self.anthropicSettings = anthropicSettings
    self.openAISettings = openAISettings
  }
  #endif

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pointReleaseXcodeExtensionToDebugApp = try container.decodeIfPresent(
      Bool.self,
      forKey: .pointReleaseXcodeExtensionToDebugApp) ?? false
    #if DEBUG
    enableAnalytics = try container.decodeIfPresent(Bool.self, forKey: .enableAnalytics) ?? true
    #else
    enableAnalytics = try container.decodeIfPresent(Bool.self, forKey: .enableAnalytics) ?? false
    #endif
    allowAnonymousAnalytics = try container.decodeIfPresent(Bool.self, forKey: .allowAnonymousAnalytics) ?? true
    anthropicSettings = try container.decodeIfPresent(Settings.AnthropicSettings.self, forKey: .anthropicSettings)
    openAISettings = try container.decodeIfPresent(Settings.OpenAISettings.self, forKey: .openAISettings)
  }

  public struct AnthropicSettings: Sendable, Codable, Equatable {
    public var apiKey: String
    public var apiUrl: String?

    public init(
      apiKey: String,
      apiUrl: String?)
    {
      self.apiKey = apiKey
      self.apiUrl = apiUrl
    }
  }

  public struct OpenAISettings: Sendable, Codable, Equatable {
    public var apiKey: String
    public var apiUrl: String?

    public init(
      apiKey: String,
      apiUrl: String?)
    {
      self.apiKey = apiKey
      self.apiUrl = apiUrl
    }
  }

  public var enableAnalytics: Bool
  public var pointReleaseXcodeExtensionToDebugApp: Bool
  public var allowAnonymousAnalytics: Bool
  public var anthropicSettings: AnthropicSettings?
  public var openAISettings: OpenAISettings?

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
