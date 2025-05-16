// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let int: Double?
    public let string: String?
    public let boolean: Bool?
    public let array: [String]?
  
    private enum CodingKeys: String, CodingKey {
      case int = "int"
      case string = "string"
      case boolean = "boolean"
      case array = "array"
    }
  
    public init(
        int: Double? = nil,
        string: String? = nil,
        boolean: Bool? = nil,
        array: [String]? = nil
    ) {
      self.int = int
      self.string = string
      self.boolean = boolean
      self.array = array
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      int = try container.decodeIfPresent(Double?.self, forKey: .int)
      string = try container.decodeIfPresent(String?.self, forKey: .string)
      boolean = try container.decodeIfPresent(Bool?.self, forKey: .boolean)
      array = try container.decodeIfPresent([String]?.self, forKey: .array)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(int, forKey: .int)
      try container.encodeIfPresent(string, forKey: .string)
      try container.encodeIfPresent(boolean, forKey: .boolean)
      try container.encodeIfPresent(array, forKey: .array)
    }
  }}
