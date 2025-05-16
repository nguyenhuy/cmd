// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct NumberType: Codable, Sendable {
    public let type = "number"
    public let value: Double
  
    private enum CodingKeys: String, CodingKey {
      case type = "type"
      case value = "value"
    }
  
    public init(
        type: String = "number",
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
  }
  public struct BooleanType: Codable, Sendable {
    public let type = "boolean"
    public let value: Bool
  
    private enum CodingKeys: String, CodingKey {
      case type = "type"
      case value = "value"
    }
  
    public init(
        type: String = "boolean",
        value: Bool
    ) {
      self.value = value
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      value = try container.decode(Bool.self, forKey: .value)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(type, forKey: .type)
      try container.encode(value, forKey: .value)
    }
  }
  public enum ValueType: Codable, Sendable {
    case numberType(_ value: NumberType)
    case booleanType(_ value: BooleanType)
  
    private enum CodingKeys: String, CodingKey {
      case type = "type"
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
        case "number":
          self = .numberType(try NumberType(from: decoder))
        case "boolean":
          self = .booleanType(try BooleanType(from: decoder))
        default:
          throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type"))
      }
    }
  
    public func encode(to encoder: Encoder) throws {
      switch self {
        case .numberType(let value):
          try value.encode(to: encoder)
        case .booleanType(let value):
          try value.encode(to: encoder)
      }
    }
  }}
