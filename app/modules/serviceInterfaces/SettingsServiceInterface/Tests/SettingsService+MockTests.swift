// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import LLMFoundation
import SwiftTesting
import Testing
@testable import SettingsServiceInterface

struct SettingsServiceMockTests {

  @Test("Direct value access")
  func test_settingValues() {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      llmProviderSettings: [
        .anthropic: LLMProviderSettings(
          apiKey: "default-key",
          baseUrl: "https://api.anthropic.com",
          createdOrder: 1),
      ])

    let sut = MockSettingsService(defaultSettings: defaultSettings)

    // Test initial values
    #expect(sut.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.apiKey) == "default-key")
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.baseUrl) == "https://api.anthropic.com")
    #expect(sut.value(for: \.llmProviderSettings[.openAI]) == nil)

    // Test updating values
    sut.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    let newAnthropicSettings = LLMProviderSettings(
      apiKey: "new-key",
      baseUrl: "https://api.anthropic.com/v1",
      createdOrder: 1)

    var newSettings = sut.value(for: \.llmProviderSettings)
    newSettings[.anthropic] = newAnthropicSettings
    sut.update(setting: \.llmProviderSettings, to: newSettings)

    #expect(sut.value(for: \.pointReleaseXcodeExtensionToDebugApp) == true)
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.apiKey) == "new-key")
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.baseUrl) == "https://api.anthropic.com/v1")

    // Test resetting individual setting
    sut.resetToDefault(setting: \.pointReleaseXcodeExtensionToDebugApp)
    #expect(sut.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.apiKey) == "new-key") // Unchanged

    // Test resetting all settings
    sut.resetAllToDefault()
    #expect(sut.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.apiKey) == "default-key")
    #expect(sut.value(for: \.llmProviderSettings[.anthropic]?.baseUrl) == "https://api.anthropic.com")
    #expect(sut.value(for: \.llmProviderSettings[.openAI]) == nil)
  }

  @Test("All values access")
  func test_allValues() {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      llmProviderSettings: [
        .anthropic: LLMProviderSettings(
          apiKey: "default-key",
          baseUrl: "https://api.anthropic.com",
          createdOrder: 1),
      ])

    let sut = MockSettingsService(defaultSettings: defaultSettings)

    // Test getting all values
    let allSettings = sut.values()
    #expect(allSettings.pointReleaseXcodeExtensionToDebugApp == false)
    #expect(allSettings.llmProviderSettings[.anthropic]?.apiKey == "default-key")
    #expect(allSettings.llmProviderSettings[.anthropic]?.baseUrl == "https://api.anthropic.com")
    #expect(allSettings.llmProviderSettings[.openAI] == nil)

    // Test updating and getting all values
    sut.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)
    let updatedSettings = sut.values()
    #expect(updatedSettings.pointReleaseXcodeExtensionToDebugApp == true)
  }

  @Test("Live value updates")
  func test_liveValues() async throws {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      llmProviderSettings: [
        .anthropic: LLMProviderSettings(
          apiKey: "default-key",
          baseUrl: "https://api.anthropic.com",
          createdOrder: 1),
      ])

    let sut = MockSettingsService(defaultSettings: defaultSettings)

    // Test live values
    var cancellables = Set<AnyCancellable>()
    var receivedValues: [Bool] = []
    let valuesReceived = expectation(description: "Values received")

    sut.liveValue(for: \.pointReleaseXcodeExtensionToDebugApp)
      .sink { value in
        receivedValues.append(value)
        if receivedValues.count == 3 {
          valuesReceived.fulfill()
        }
      }
      .store(in: &cancellables)

    // Initial value should be received
    #expect(receivedValues.count == 1)
    #expect(receivedValues.first == false)

    // Update value
    sut.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    // Reset value
    sut.resetToDefault(setting: \.pointReleaseXcodeExtensionToDebugApp)

    try await fulfillment(of: [valuesReceived])
    #expect(receivedValues == [false, true, false])
  }

  @Test("Live all values updates")
  func test_liveAllValues() async throws {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      llmProviderSettings: [
        .anthropic: LLMProviderSettings(
          apiKey: "default-key",
          baseUrl: "https://api.anthropic.com",
          createdOrder: 1),
      ])

    let sut = MockSettingsService(defaultSettings: defaultSettings)

    // Test live all values
    var cancellables = Set<AnyCancellable>()
    var receivedSettings: [Settings] = []
    let settingsReceived = expectation(description: "Settings received")

    sut.liveValues()
      .sink { settings in
        receivedSettings.append(settings)
        if receivedSettings.count == 3 {
          settingsReceived.fulfill()
        }
      }
      .store(in: &cancellables)

    // Initial value should be received
    #expect(receivedSettings.count == 1)
    #expect(receivedSettings[0].pointReleaseXcodeExtensionToDebugApp == false)

    // Update value
    sut.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    // Reset all values
    sut.resetAllToDefault()

    try await fulfillment(of: [settingsReceived])
    #expect(receivedSettings.count == 3)
    #expect(receivedSettings[0].pointReleaseXcodeExtensionToDebugApp == false)
    #expect(receivedSettings[1].pointReleaseXcodeExtensionToDebugApp == true)
    #expect(receivedSettings[2].pointReleaseXcodeExtensionToDebugApp == false)
  }
}
