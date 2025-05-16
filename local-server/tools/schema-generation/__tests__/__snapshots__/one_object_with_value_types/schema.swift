// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let int: Double
    public let string: String
    public let boolean: Bool
    public let array: [String]
  
    private enum CodingKeys: String, CodingKey {
      case int = "int"
      case string = "string"
      case boolean = "boolean"
      case array = "array"
    }
  
    public init(
        int: Double,
        string: String,
        boolean: Bool,
        array: [String]
    ) {
      self.int = int
      self.string = string
      self.boolean = boolean
      self.array = array
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      int = try container.decode(Double.self, forKey: .int)
      string = try container.decode(String.self, forKey: .string)
      boolean = try container.decode(Bool.self, forKey: .boolean)
      array = try container.decode([String].self, forKey: .array)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(int, forKey: .int)
      try container.encode(string, forKey: .string)
      try container.encode(boolean, forKey: .boolean)
      try container.encode(array, forKey: .array)
    }
  }}
