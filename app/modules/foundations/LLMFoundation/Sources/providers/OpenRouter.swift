// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation

extension LLMProvider {

  public static let openRouter = LLMProvider(
    id: "openrouter",
    name: "OpenRouter",
    keychainKey: "OPENROUTER_API_KEY",
    supportedModels: [
      .claudeHaiku_3_5,
      .claudeSonnet_3_7,
      .claudeSonnet_4_0,
      .claudeOpus_4,
      .gpt_4_1,
      .gpt_4o,
      .o3,
      .o4_mini,
    ],
    idForModel: { model in
      switch model {
      case .claudeHaiku_3_5: return "anthropic/claude-3.5-haiku"
      case .claudeSonnet_3_7: return "anthropic/claude-3.7-sonnet"
      case .claudeSonnet_4_0: return "anthropic/claude-sonnet-4"
      case .claudeOpus_4: return "anthropic/claude-opus-4"
      case .gpt_4_1: return "openai/gpt-4.1"
      case .gpt_4o: return "openai/gpt-4o"
      case .o3: return "openai/o3"
      case .o4_mini: return "openai/o4-mini"
      default: throw AppError(message: "Model \(model) is not supported by Anthropic provider.")
      }
    },
    priceForModel: { model in
      model.defaultPricing
    })
}
