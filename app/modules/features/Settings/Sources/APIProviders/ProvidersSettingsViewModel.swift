// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

// MARK: - APIProvider

enum APIProvider: String, CaseIterable {
  case anthropic = "Anthropic"
  case openAI = "Open AI"
}

// MARK: - ProviderSettings

enum ProviderSettings {
  case anthropic(AnthropicProviderSettings)
  case openAI(OpenAIProviderSettings)

  var provider: APIProvider {
    switch self {
    case .anthropic:
      .anthropic
    case .openAI:
      .openAI
    }
  }
}

// MARK: - AnthropicProviderSettings

struct AnthropicProviderSettings {
  var apiKey: String
  var apiUrl: String?
}

// MARK: - OpenAIProviderSettings

struct OpenAIProviderSettings {
  var apiKey: String
}
