// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMFoundation
import SettingsServiceInterface

extension Settings: Codable {

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: String.self)
    try self.init(
      pointReleaseXcodeExtensionToDebugApp: container
        .decodeIfPresent(Bool.self, forKey: "pointReleaseXcodeExtensionToDebugApp") ?? false,
      allowAnonymousAnalytics: container.decodeIfPresent(Bool.self, forKey: "allowAnonymousAnalytics") ?? true,
      preferedProviders: container.decodeIfPresent([String: String].self, forKey: "preferedProviders")?
        .reduce(into: [LLMModel: LLMProvider]()) { acc, el in
          guard let model = LLMModel(rawValue: el.key), let provider = LLMProvider(rawValue: el.value) else { return }
          acc[model] = provider
        } ?? [:],
      llmProviderSettings: container
        .decodeIfPresent([String: LLMProviderSettings].self, forKey: "llmProviderSettings")?
        .reduce(into: [LLMProvider: LLMProviderSettings]()) { acc, el in
          guard let provider = LLMProvider(rawValue: el.key) else { return }
          acc[provider] = el.value
        } ?? [:],
      inactiveModels: container
        .decodeIfPresent([String].self, forKey: "inactiveModels")?
        .compactMap { modelName in LLMModel(rawValue: modelName) } ?? [])
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: String.self)
    try container.encode(pointReleaseXcodeExtensionToDebugApp, forKey: "pointReleaseXcodeExtensionToDebugApp")
    try container.encode(allowAnonymousAnalytics, forKey: "allowAnonymousAnalytics")
    try container.encode(preferedProviders.reduce(into: [String: String]()) { acc, el in
      acc[el.key.rawValue] = el.value.rawValue
    }, forKey: "preferedProviders")
    try container.encode(llmProviderSettings.reduce(into: [String: LLMProviderSettings]()) { acc, el in
      acc[el.key.rawValue] = el.value
    }, forKey: "llmProviderSettings")
    try container.encode(inactiveModels.map(\.rawValue), forKey: "inactiveModels")
  }
}
