// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppFoundation
import LLMFoundation

extension SettingsServiceInterface.Settings {
  /// The LLM models that have been configured and are available for use.
  public var availableModels: [LLMModel] {
    var models = Set<LLMModel>()
    if llmProviderSettings[.anthropic] != nil {
      for supportedModel in LLMProvider.anthropic.supportedModels { models.insert(supportedModel) }
    }
    if llmProviderSettings[.openAI] != nil {
      for supportedModel in LLMProvider.openAI.supportedModels { models.insert(supportedModel) }
    }
    if llmProviderSettings[.openRouter] != nil {
      for supportedModel in LLMProvider.openRouter.supportedModels { models.insert(supportedModel) }
    }
    return LLMModel.allCases.filter { models.contains($0) }
  }

  /// The active models. A model might be available (one of its provider is configured), but inactive as the user doesn't want to use it.
  public var activeModels: [LLMModel] {
    availableModels.filter { !inactiveModels.contains($0) }
  }

  /// The provider for a given model, and its configuration.
  public func provider(for model: LLMModel) throws -> (LLMProvider, LLMProviderSettings) {
    let preferedProviders = preferedProviders[model]
    let provider = llmProviderSettings
      .filter { $0.key.supportedModels.contains(model) }
      .sorted(by: { a, b in
        if a.key == preferedProviders {
          return true
        } else if b.key == preferedProviders {
          return false
        }
        return a.value.createdOrder < b.value.createdOrder
      })
      .first
    guard let provider else {
      throw AppError(message: "Unsupported model \(model.name)")
    }
    return (provider.key, provider.value)
  }
}
