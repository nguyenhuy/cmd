// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let type = "value"
    public let value: Double
  
    private enum CodingKeys: String, CodingKey {
      case type = "type"
      case value = "value"
    }
  
    public init(
        type: String = "value",
        value: Double
    ) {
      self.value = value
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      value = try container.decode(Double.self, forKey: .value)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(type, forKey: .type)
      try container.encode(value, forKey: .value)
    }
  }}
