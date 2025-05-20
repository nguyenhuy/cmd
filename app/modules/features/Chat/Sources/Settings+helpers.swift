// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMServiceInterface
import SettingsServiceInterface

extension SettingsServiceInterface.Settings {
  /// The LLM models that have been configured and are available for use.
  var availableModels: [LLMModel] {
    let allModels: [LLMModel] = [.claudeSonnet, .gpt4o]
    return allModels.filter { model in
      switch model {
      case .claudeSonnet:
        anthropicSettings != nil
      case .gpt4o, .gpt4o_mini, .o1:
        openAISettings != nil
      default:
        false
      }
    }
  }
}
