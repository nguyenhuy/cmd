// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMFoundation
import SettingsServiceInterface

extension SettingsServiceInterface.Settings {
  /// The LLM models that have been configured and are available for use.
  var availableModels: [LLMModel] {
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
}
