// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

// MARK: - LLMProvider

public struct LLMProvider: Hashable, Identifiable, CaseIterable, Sendable {
  public init?(rawValue: String) {
    if let provider = LLMProvider.allCases.first(where: { $0.id == rawValue }) {
      self = provider
    } else {
      return nil
    }
  }

  init(
    id: String,
    name: String,
    keychainKey: String,
    supportedModels: [LLMModel] = [],
    idForModel: @escaping @Sendable (LLMModel) throws -> String,
    priceForModel: @escaping @Sendable (LLMModel) -> ModelPricing?)
  {
    self.id = id
    self.name = name
    self.keychainKey = keychainKey
    self.supportedModels = supportedModels
    self.idForModel = idForModel
    self.priceForModel = priceForModel
  }

  public static var allCases: [LLMProvider] {
    [
      .openRouter,
      .anthropic,
      .openAI,
    ]
  }

  public let id: String
  public let name: String
  public let keychainKey: String
  public let supportedModels: [LLMModel]

  public static func ==(lhs: LLMProvider, rhs: LLMProvider) -> Bool {
    lhs.id == rhs.id
  }

  public func id(for model: LLMModel) throws -> String {
    try idForModel(model)
  }

  public func price(for model: LLMModel) -> ModelPricing? {
    priceForModel(model)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  private let idForModel: @Sendable (LLMModel) throws -> String
  private let priceForModel: @Sendable (LLMModel) -> ModelPricing?

}

// MARK: Codable

extension LLMProvider: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let id = try container.decode(String.self)
    guard let provider = LLMProvider(rawValue: id) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid LLMProvider \(id)")
    }
    self = provider
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(id)
  }
}
