// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppFoundation

extension LLMProvider {

  public static let openAI = LLMProvider(
    id: "openai",
    name: "OpenAI",
    keychainKey: "OPENAI_API_KEY",
    supportedModels: [
      .gpt_4_1,
      .gpt_4o,
      .o3,
      .o4_mini,
    ],
    idForModel: { model in
      switch model {
      case .gpt_4_1: return "gpt-4.1"
      case .gpt_4o: return "gpt-4o"
      case .o3: return "o3"
      case .o4_mini: return "o4-mini"
      default: throw AppError(message: "Model \(model) is not supported by Anthropic provider.")
      }
    },
    priceForModel: { model in
      model.defaultPricing
    })
}
