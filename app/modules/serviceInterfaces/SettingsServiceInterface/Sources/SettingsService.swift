// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation
import JSONFoundation
import LLMFoundation

// MARK: - LLMReasoningSetting

public struct LLMReasoningSetting: Sendable, Equatable {
  public var isEnabled: Bool
  public init(isEnabled: Bool) {
    self.isEnabled = isEnabled
  }
}

// MARK: - Settings

public struct Settings: Sendable, Equatable {
  public init(
    pointReleaseXcodeExtensionToDebugApp: Bool,
    allowAnonymousAnalytics: Bool = false,
    automaticallyCheckForUpdates: Bool = true,
    preferedProviders: [LLMModel: LLMProvider] = [:],
    llmProviderSettings: [LLMProvider: LLMProviderSettings] = [:],
    inactiveModels: [LLMModel] = [],
    reasoningModels: [LLMModel: LLMReasoningSetting] = [:],
    customInstructions: CustomInstructions = CustomInstructions(),
    toolPreferences: [ToolPreference] = [])
  {
    self.pointReleaseXcodeExtensionToDebugApp = pointReleaseXcodeExtensionToDebugApp
    self.allowAnonymousAnalytics = allowAnonymousAnalytics
    self.automaticallyCheckForUpdates = automaticallyCheckForUpdates
    self.preferedProviders = preferedProviders
    self.llmProviderSettings = llmProviderSettings
    self.inactiveModels = inactiveModels
    self.reasoningModels = reasoningModels
    self.customInstructions = customInstructions
    self.toolPreferences = toolPreferences
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

  public struct CustomInstructions: Sendable, Codable, Equatable {
    public var askMode: String?
    public var agentMode: String?

    public init(askModePrompt: String? = nil, agentModePrompt: String? = nil) {
      askMode = askModePrompt
      agentMode = agentModePrompt
    }
  }

  public struct ToolPreference: Sendable, Codable, Equatable {
    public let toolName: String
    public var alwaysApprove: Bool

    public init(toolName: String, alwaysApprove: Bool = false) {
      self.toolName = toolName
      self.alwaysApprove = alwaysApprove
    }
  }

  public var allowAnonymousAnalytics: Bool
  public var pointReleaseXcodeExtensionToDebugApp: Bool
  public var automaticallyCheckForUpdates: Bool
  // LLM settings
  public var preferedProviders: [LLMModel: LLMProvider]
  public var llmProviderSettings: [LLMProvider: LLMProviderSettings]
  public var reasoningModels: [LLMModel: LLMReasoningSetting]

  public var inactiveModels: [LLMModel]
  public var customInstructions: CustomInstructions
  public var toolPreferences: [ToolPreference]

}

// MARK: - Settings + Tool Preferences Helpers

extension Settings {
  public func toolPreference(for toolName: String) -> ToolPreference? {
    toolPreferences.first { $0.toolName == toolName }
  }

  public mutating func setToolPreference(toolName: String, alwaysApprove: Bool) {
    if let index = toolPreferences.firstIndex(where: { $0.toolName == toolName }) {
      toolPreferences[index].alwaysApprove = alwaysApprove
    } else {
      toolPreferences.append(ToolPreference(toolName: toolName, alwaysApprove: alwaysApprove))
    }
  }

  public func shouldAlwaysApprove(toolName: String) -> Bool {
    toolPreferences.first { $0.toolName == toolName }?.alwaysApprove ?? false
  }
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

public typealias UserDefaultsKey = String

extension UserDefaultsKey {
  public static let hasCompletedOnboardingUserDefaultsKey = "hasCompletedOnboarding"
  public static let showInternalSettingsInRelease = "showInternalSettingsInRelease"
  public static let defaultChatPositionIsInverted = "defaultChatPositionIsInverted"
  public static let repeatLastLLMInteraction = "llmService.isRepeating"
}
