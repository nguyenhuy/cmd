// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation

extension LLMProvider {

  public static let anthropic = LLMProvider(
    id: "anthropic",
    name: "Anthropic",
    keychainKey: "ANTHROPIC_API_KEY",
    supportedModels: [
      .claudeHaiku_3_5,
      .claudeSonnet_3_7,
      .claudeSonnet_4_0,
      .claudeOpus_4,
    ],
    idForModel: { model in
      switch model {
      case .claudeHaiku_3_5: return "claude-3-5-haiku-latest"
      case .claudeSonnet_3_7: return "claude-3-7-sonnet-latest"
      case .claudeSonnet_4_0: return "claude-sonnet-4-0"
      case .claudeOpus_4: return "claude-opus-4-0"
      default: throw AppError(message: "Model \(model) is not supported by Anthropic provider.")
      }
    },
    priceForModel: { model in
      model.defaultPricing
    })
}
