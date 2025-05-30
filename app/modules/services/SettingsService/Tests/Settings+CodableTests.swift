// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import LLMFoundation
import SettingsServiceInterface
import SwiftTesting
import Testing

@testable import SettingsService

@Suite("Settings+Codable Tests")
struct SettingsCodableTests {

  @Test("Encode and decode basic settings")
  func testBasicSettingsEncodingDecoding() throws {
    let settings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: false,
      preferedProviders: ["model1": "anthropic", "model2": "openai"],
      llmProviderSettings: [:])

    let json = """
      {
        "allowAnonymousAnalytics" : false,
        "llmProviderSettings" : {

        },
        "pointReleaseXcodeExtensionToDebugApp" : true,
        "preferedProviders" : {
          "model1" : "anthropic",
          "model2" : "openai"
        }
      }
      """

    try testEncodingDecoding(settings, json)
  }

  @Test("Encode and decode settings with LLM provider settings")
  func testSettingsWithLLMProviderSettings() throws {
    let providerSettings = Settings.LLMProviderSettings(
      apiKey: "test-api-key",
      baseUrl: "https://api.example.com",
      createdOrder: 1)

    let settings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      allowAnonymousAnalytics: true,
      preferedProviders: [:],
      llmProviderSettings: [.anthropic: providerSettings])

    let json = """
      {
        "allowAnonymousAnalytics" : true,
        "llmProviderSettings" : {
          "anthropic" : {
            "apiKey" : "test-api-key",
            "baseUrl" : "https://api.example.com",
            "createdOrder" : 1
          }
        },
        "pointReleaseXcodeExtensionToDebugApp" : false,
        "preferedProviders" : {

        }
      }
      """

    try testEncodingDecoding(settings, json)
  }

  @Test("Encode and decode settings with multiple LLM providers")
  func testSettingsWithMultipleLLMProviders() throws {
    let anthropicSettings = Settings.LLMProviderSettings(
      apiKey: "anthropic-key",
      baseUrl: nil,
      createdOrder: 1)

    let openAISettings = Settings.LLMProviderSettings(
      apiKey: "openai-key",
      baseUrl: "https://api.openai.com",
      createdOrder: 2)

    let settings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: true,
      preferedProviders: ["default": "anthropic"],
      llmProviderSettings: [
        .anthropic: anthropicSettings,
        .openAI: openAISettings,
      ])

    let json = """
      {
        "allowAnonymousAnalytics" : true,
        "llmProviderSettings" : {
          "anthropic" : {
            "apiKey" : "anthropic-key",
            "createdOrder" : 1
          },
          "openai" : {
            "apiKey" : "openai-key",
            "baseUrl" : "https://api.openai.com",
            "createdOrder" : 2
          }
        },
        "pointReleaseXcodeExtensionToDebugApp" : true,
        "preferedProviders" : {
          "default" : "anthropic"
        }
      }
      """

    try testEncodingDecoding(settings, json)
  }

  @Test("Decode settings with missing optional fields uses defaults")
  func testDecodingWithMissingOptionalFields() throws {
    let json = """
      {
      }
      """

    let expectedSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      allowAnonymousAnalytics: true,
      preferedProviders: [:],
      llmProviderSettings: [:])

    try testDecoding(expectedSettings, json)
  }

  @Test("Decode settings with partial data")
  func testDecodingWithPartialData() throws {
    let json = """
      {
        "pointReleaseXcodeExtensionToDebugApp" : true,
        "preferedProviders" : {
          "model1" : "openai"
        }
      }
      """

    let expectedSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: true, // default
      preferedProviders: ["model1": "openai"],
      llmProviderSettings: [:] // default
    )

    try testDecoding(expectedSettings, json)
  }

  @Test("Decode settings ignores invalid LLM provider keys")
  func testDecodingIgnoresInvalidLLMProviderKeys() throws {
    let json = """
      {
        "allowAnonymousAnalytics" : false,
        "llmProviderSettings" : {
          "invalid-provider" : {
            "apiKey" : "test-key",
            "createdOrder" : 1
          },
          "anthropic" : {
            "apiKey" : "anthropic-key",
            "createdOrder" : 2
          }
        },
        "pointReleaseXcodeExtensionToDebugApp" : true,
        "preferedProviders" : {

        }
      }
      """

    let anthropicSettings = Settings.LLMProviderSettings(
      apiKey: "anthropic-key",
      baseUrl: nil,
      createdOrder: 2)

    let expectedSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: false,
      preferedProviders: [:],
      llmProviderSettings: [.anthropic: anthropicSettings])

    try testDecoding(expectedSettings, json)
  }

  @Test("Round-trip encoding and decoding preserves data")
  func testRoundTripEncodingDecoding() throws {
    let originalSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: false,
      preferedProviders: ["model1": "anthropic", "model2": "openai"],
      llmProviderSettings: [
        .anthropic: Settings.LLMProviderSettings(
          apiKey: "anthropic-key",
          baseUrl: nil,
          createdOrder: 1),
        .openRouter: Settings.LLMProviderSettings(
          apiKey: "openrouter-key",
          baseUrl: "https://openrouter.ai/api/v1",
          createdOrder: 3),
      ])

    let jsonData = try JSONEncoder().encode(originalSettings)
    let decodedSettings = try JSONDecoder().decode(Settings.self, from: jsonData)

    #expect(originalSettings == decodedSettings)
  }

  @Test("Encoding handles empty LLM provider settings")
  func testEncodingEmptyLLMProviderSettings() throws {
    let settings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      allowAnonymousAnalytics: true,
      preferedProviders: [:],
      llmProviderSettings: [:])

    let json = """
      {
        "allowAnonymousAnalytics" : true,
        "llmProviderSettings" : {

        },
        "pointReleaseXcodeExtensionToDebugApp" : false,
        "preferedProviders" : {

        }
      }
      """

    try testEncoding(settings, json)
  }

  @Test("Decoding with null baseUrl works correctly")
  func testDecodingWithNullBaseUrl() throws {
    let json = """
      {
        "allowAnonymousAnalytics" : true,
        "llmProviderSettings" : {
          "anthropic" : {
            "apiKey" : "test-key",
            "baseUrl" : null,
            "createdOrder" : 1
          }
        },
        "pointReleaseXcodeExtensionToDebugApp" : false,
        "preferedProviders" : {

        }
      }
      """

    let expectedSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      allowAnonymousAnalytics: true,
      preferedProviders: [:],
      llmProviderSettings: [
        .anthropic: Settings.LLMProviderSettings(
          apiKey: "test-key",
          baseUrl: nil,
          createdOrder: 1),
      ])

    try testDecoding(expectedSettings, json)
  }

  @Test("Decoding large settings data")
  func testDecodingLargeSettingsData() throws {
    let json = """
      {
        "allowAnonymousAnalytics" : false,
        "llmProviderSettings" : {
          "anthropic" : {
            "apiKey" : "anthropic-very-long-api-key-for-testing-purposes",
            "baseUrl" : "https://api.anthropic.com/v1/messages",
            "createdOrder" : 1
          },
          "openai" : {
            "apiKey" : "openai-very-long-api-key-for-testing-purposes",
            "baseUrl" : "https://api.openai.com/v1/chat/completions",
            "createdOrder" : 2
          },
          "openrouter" : {
            "apiKey" : "openrouter-very-long-api-key-for-testing-purposes",
            "baseUrl" : "https://openrouter.ai/api/v1",
            "createdOrder" : 3
          }
        },
        "pointReleaseXcodeExtensionToDebugApp" : true,
        "preferedProviders" : {
          "claude-3-5-sonnet-20241022" : "anthropic",
          "gpt-4o" : "openai",
          "gpt-4o-mini" : "openai",
          "claude-3-haiku-20240307" : "anthropic"
        }
      }
      """

    let expectedSettings = Settings(
      pointReleaseXcodeExtensionToDebugApp: true,
      allowAnonymousAnalytics: false,
      preferedProviders: [
        "claude-3-5-sonnet-20241022": "anthropic",
        "gpt-4o": "openai",
        "gpt-4o-mini": "openai",
        "claude-3-haiku-20240307": "anthropic",
      ],
      llmProviderSettings: [
        .anthropic: Settings.LLMProviderSettings(
          apiKey: "anthropic-very-long-api-key-for-testing-purposes",
          baseUrl: "https://api.anthropic.com/v1/messages",
          createdOrder: 1),
        .openAI: Settings.LLMProviderSettings(
          apiKey: "openai-very-long-api-key-for-testing-purposes",
          baseUrl: "https://api.openai.com/v1/chat/completions",
          createdOrder: 2),
        .openRouter: Settings.LLMProviderSettings(
          apiKey: "openrouter-very-long-api-key-for-testing-purposes",
          baseUrl: "https://openrouter.ai/api/v1",
          createdOrder: 3),
      ])

    try testDecoding(expectedSettings, json)
  }
}
