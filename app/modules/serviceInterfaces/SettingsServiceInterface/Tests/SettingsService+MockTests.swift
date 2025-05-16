// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import SwiftTesting
import Testing
@testable import SettingsServiceInterface

struct SettingsServiceMockTests {

  @Test("Direct value access")
  func test_settingValues() {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: Settings.AnthropicSettings(
        apiKey: "default-key",
        apiUrl: "https://api.anthropic.com"),
      openAISettings: nil)

    let mockService = MockSettingsService(defaultSettings: defaultSettings)

    // Test initial values
    #expect(mockService.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(mockService.value(for: \.anthropicSettings?.apiKey) == "default-key")
    #expect(mockService.value(for: \.anthropicSettings?.apiUrl) == "https://api.anthropic.com")
    #expect(mockService.value(for: \.openAISettings) == nil)

    // Test updating values
    mockService.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    let newAnthropicSettings = Settings.AnthropicSettings(
      apiKey: "new-key",
      apiUrl: "https://api.anthropic.com/v1")
    mockService.update(setting: \.anthropicSettings, to: newAnthropicSettings)

    #expect(mockService.value(for: \.pointReleaseXcodeExtensionToDebugApp) == true)
    #expect(mockService.value(for: \.anthropicSettings?.apiKey) == "new-key")
    #expect(mockService.value(for: \.anthropicSettings?.apiUrl) == "https://api.anthropic.com/v1")

    // Test resetting individual setting
    mockService.resetToDefault(setting: \.pointReleaseXcodeExtensionToDebugApp)
    #expect(mockService.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(mockService.value(for: \.anthropicSettings?.apiKey) == "new-key") // Unchanged

    // Test resetting all settings
    mockService.resetAllToDefault()
    #expect(mockService.value(for: \.pointReleaseXcodeExtensionToDebugApp) == false)
    #expect(mockService.value(for: \.anthropicSettings?.apiKey) == "default-key")
    #expect(mockService.value(for: \.anthropicSettings?.apiUrl) == "https://api.anthropic.com")
    #expect(mockService.value(for: \.openAISettings) == nil)
  }

  @Test("All values access")
  func test_allValues() {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: Settings.AnthropicSettings(
        apiKey: "default-key",
        apiUrl: "https://api.anthropic.com"),
      openAISettings: nil)

    let mockService = MockSettingsService(defaultSettings: defaultSettings)

    // Test getting all values
    let allSettings = mockService.values()
    #expect(allSettings.pointReleaseXcodeExtensionToDebugApp == false)
    #expect(allSettings.anthropicSettings?.apiKey == "default-key")
    #expect(allSettings.anthropicSettings?.apiUrl == "https://api.anthropic.com")
    #expect(allSettings.openAISettings == nil)

    // Test updating and getting all values
    mockService.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)
    let updatedSettings = mockService.values()
    #expect(updatedSettings.pointReleaseXcodeExtensionToDebugApp == true)
  }

  @Test("Live value updates")
  func test_liveValues() async throws {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: Settings.AnthropicSettings(
        apiKey: "default-key",
        apiUrl: "https://api.anthropic.com"),
      openAISettings: nil)

    let mockService = MockSettingsService(defaultSettings: defaultSettings)

    // Test live values
    var cancellables = Set<AnyCancellable>()
    var receivedValues: [Bool] = []
    let valuesReceived = expectation(description: "Values received")

    mockService.liveValue(for: \.pointReleaseXcodeExtensionToDebugApp)
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
    mockService.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    // Reset value
    mockService.resetToDefault(setting: \.pointReleaseXcodeExtensionToDebugApp)

    try await fulfillment(of: [valuesReceived])
    #expect(receivedValues == [false, true, false])
  }

  @Test("Live all values updates")
  func test_liveAllValues() async throws {
    // Setup
    let defaultSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: Settings.AnthropicSettings(
        apiKey: "default-key",
        apiUrl: "https://api.anthropic.com"),
      openAISettings: nil)

    let mockService = MockSettingsService(defaultSettings: defaultSettings)

    // Test live all values
    var cancellables = Set<AnyCancellable>()
    var receivedSettings: [Settings] = []
    let settingsReceived = expectation(description: "Settings received")

    mockService.liveValues()
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
    mockService.update(setting: \.pointReleaseXcodeExtensionToDebugApp, to: true)

    // Reset all values
    mockService.resetAllToDefault()

    try await fulfillment(of: [settingsReceived])
    #expect(receivedSettings.count == 3)
    #expect(receivedSettings[0].pointReleaseXcodeExtensionToDebugApp == false)
    #expect(receivedSettings[1].pointReleaseXcodeExtensionToDebugApp == true)
    #expect(receivedSettings[2].pointReleaseXcodeExtensionToDebugApp == false)
  }
}
