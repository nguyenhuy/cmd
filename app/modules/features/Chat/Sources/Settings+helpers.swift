// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMServiceInterface
import SettingsServiceInterface

extension SettingsServiceInterface.Settings {
  /// The LLM models that have been configured and are available for use.
  var availableModels: [LLMModel] {
    let allModels: [LLMModel] = LLMModel.allCases
    return allModels.filter { model in
      switch model {
      case .claudeSonnet40, .claudeSonnet37:
        anthropicSettings != nil
      case .gpt4o, .gpt4o_mini, .o1:
        openAISettings != nil
      case .openRouterClaudeSonnet37,
           .openRouterClaudeSonnet40,
           .openRouterClaudeOpus4,
           .openRouterClaudeHaiku35,
           .openRouterGpt41,
           .openRouterGpt4o,
           .openRouterO4Mini:
        openRouterSettings != nil
      default:
        false
      }
    }
  }
}
