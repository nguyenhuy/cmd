// Copyright Xcompanion. All rights reserved.
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
    preferedProviders: [LLMModel: LLMProvider] = [:],
    llmProviderSettings: [LLMProvider: LLMProviderSettings] = [:],
    inactiveModels: [LLMModel] = [])
  {
    self.pointReleaseXcodeExtensionToDebugApp = pointReleaseXcodeExtensionToDebugApp
    self.allowAnonymousAnalytics = allowAnonymousAnalytics
    self.preferedProviders = preferedProviders
    self.llmProviderSettings = llmProviderSettings
    self.inactiveModels = inactiveModels
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
  // LLM settings
  public var preferedProviders: [LLMModel: LLMProvider]
  public var llmProviderSettings: [LLMProvider: LLMProviderSettings]

  public var inactiveModels: [LLMModel]

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
