// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let nestedValue: NestedValueType
  
    private enum CodingKeys: String, CodingKey {
      case nestedValue = "nested_value"
    }
  
    public init(
        nestedValue: NestedValueType
    ) {
      self.nestedValue = nestedValue
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      nestedValue = try container.decode(NestedValueType.self, forKey: .nestedValue)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(nestedValue, forKey: .nestedValue)
    }
  }
  public struct NestedValueType: Codable, Sendable {
    public let value: String
  
    private enum CodingKeys: String, CodingKey {
      case value = "value"
    }
  
    public init(
        value: String
    ) {
      self.value = value
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      value = try container.decode(String.self, forKey: .value)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(value, forKey: .value)
    }
  }}
