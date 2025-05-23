// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import ConcurrencyFoundation
import Dependencies
import FileSuggestionServiceInterface
import Foundation
import FoundationInterfaces
import LLMServiceInterface
import SettingsServiceInterface
import SwiftTesting
import Testing
import XcodeObserverServiceInterface
@testable import Chat

// MARK: - ChatInputViewModelTests

struct ChatInputViewModelTests {

  @MainActor
  @Test("initializing with a selected model that is in available models keeps that model")
  func test_initialization_withSelectedModelInAvailableModels() {
    let selectedModel = LLMModel.gpt4o
    let availableModels = [LLMModel.claudeSonnet40, LLMModel.gpt4o]
    let mockSettingsService = MockSettingsService.allConfigured

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel(
        selectedModel: selectedModel,
        availableModels: availableModels)
    }

    #expect(viewModel.selectedModel == selectedModel)
  }

  @MainActor
  @Test("initializing with a selected model that is not in available models selects the first available model")
  func test_initialization_withSelectedModelNotInAvailableModels() {
    let selectedModel = LLMModel.o1
    let availableModels = [LLMModel.claudeSonnet40, LLMModel.gpt4o]
    let mockSettingsService = MockSettingsService.allConfigured

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel(
        selectedModel: selectedModel,
        availableModels: availableModels)
    }

    #expect(viewModel.selectedModel == availableModels.first)
  }

  @MainActor
  @Test("initializing with nil selected model selects the first available model")
  func test_initialization_withNilSelectedModel() {
    let availableModels = [LLMModel.claudeSonnet40, LLMModel.gpt4o]
    let mockSettingsService = MockSettingsService.allConfigured

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel(
        selectedModel: nil,
        availableModels: availableModels)
    }

    #expect(viewModel.selectedModel == availableModels.first)
  }

  @MainActor
  @Test("initializing with empty available models results in nil selected model")
  func test_initialization_withEmptyAvailableModels() {
    let mockSettingsService = MockSettingsService.allConfigured

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel(
        selectedModel: nil,
        availableModels: [])
    }

    #expect(viewModel.selectedModel == nil)
  }

  @MainActor
  @Test("updating available models keeps selected model if it's still available")
  func test_updatingAvailableModels_keepsSelectedModelIfStillAvailable() {
    let mockSettingsService = MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "", apiUrl: nil),
      openAISettings: .init(apiKey: "", apiUrl: nil)))
    let mockUserDefaults = MockUserDefaults()

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
      $0.userDefaults = mockUserDefaults
    } operation: {
      ChatInputViewModel(
        selectedModel: .gpt4o,
        availableModels: [.claudeSonnet40, .gpt4o, .gpt4o_mini])
    }

    #expect(viewModel.selectedModel == .gpt4o)
  }

  @MainActor
  @Test("updating available models changes selected model if it's no longer available")
  func test_updatingAvailableModels_changesSelectedModelIfNoLongerAvailable() {
    let mockSettingsService = MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "", apiUrl: nil),
      openAISettings: .init(apiKey: "", apiUrl: nil)))
    let mockUserDefaults = MockUserDefaults()

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
      $0.userDefaults = mockUserDefaults
    } operation: {
      ChatInputViewModel(
        selectedModel: .claudeSonnet40,
        availableModels: nil)
    }

    #expect(viewModel.selectedModel == .claudeSonnet40)
    mockSettingsService.update(setting: \.anthropicSettings, to: nil)

    #expect(viewModel.selectedModel == .gpt4o)
  }

  @MainActor
  @Test("updating available models to empty array sets selected model to nil")
  func test_updatingAvailableModels_toEmptyArray() {
    let mockSettingsService = MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "", apiUrl: nil),
      openAISettings: nil))
    let mockUserDefaults = MockUserDefaults()

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
      $0.userDefaults = mockUserDefaults
    } operation: {
      ChatInputViewModel(
        selectedModel: .claudeSonnet40,
        availableModels: nil)
    }

    #expect(viewModel.selectedModel == .claudeSonnet40)
    mockSettingsService.update(setting: \.anthropicSettings, to: nil)

    #expect(viewModel.selectedModel == nil)
  }

  @MainActor
  @Test("initializing with userDefaults selected model")
  func test_initialization_withUserDefaultsSelectedModel() {
    let mockUserDefaults = MockUserDefaults(initialValues: [
      "selectedLLMModel": "gpt-4o",
    ])
    let mockSettingsService = MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "", apiUrl: nil),
      openAISettings: .init(apiKey: "", apiUrl: nil)))

    let viewModel = withDependencies {
      $0.userDefaults = mockUserDefaults
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel()
    }

    #expect(viewModel.selectedModel == .gpt4o)
  }

  @MainActor
  @Test("changing selected model updates user defaults")
  func test_changingSelectedModel_updatesUserDefaults() {
    let mockUserDefaults = MockUserDefaults()
    let mockSettingsService = MockSettingsService.allConfigured

    let viewModel = withDependencies {
      $0.userDefaults = mockUserDefaults
      $0.settingsService = mockSettingsService
    } operation: {
      ChatInputViewModel(
        selectedModel: .claudeSonnet40,
        availableModels: [.claudeSonnet40, .gpt4o])
    }

    #expect(mockUserDefaults.string(forKey: "selectedLLMModel") == nil)
    viewModel.selectedModel = .gpt4o

    #expect(mockUserDefaults.string(forKey: "selectedLLMModel") == "gpt-4o")
  }

  @MainActor
  @Test("initializing with settings service and observing changes")
  func test_initialization_withSettingsServiceAndObservingChanges() async throws {
    let mockSettingsService = MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "test", apiUrl: nil),
      openAISettings: .init(apiKey: "test", apiUrl: nil)))
    let mockUserDefaults = MockUserDefaults()

    let viewModel = withDependencies {
      $0.settingsService = mockSettingsService
      $0.userDefaults = mockUserDefaults
    } operation: {
      ChatInputViewModel(
        selectedModel: .claudeSonnet40,
        availableModels: nil) // Pass nil to read from the settings service
    }

    #expect(viewModel.availableModels.count == 2)
    #expect(viewModel.selectedModel == .claudeSonnet40)

    mockSettingsService.update(setting: \.openAISettings, to: nil)

    #expect(viewModel.availableModels.count == 1)
    #expect(viewModel.availableModels.contains(.claudeSonnet40))
    #expect(!viewModel.availableModels.contains(.gpt4o))
    #expect(viewModel.selectedModel == .claudeSonnet40)

    mockSettingsService.update(setting: \.anthropicSettings, to: nil)

    #expect(viewModel.availableModels.isEmpty)
    #expect(viewModel.selectedModel == nil)
  }
}

extension MockSettingsService {
  static var allConfigured: MockSettingsService {
    MockSettingsService(Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      anthropicSettings: .init(apiKey: "test", apiUrl: nil),
      openAISettings: .init(apiKey: "test", apiUrl: nil)))
  }
}
