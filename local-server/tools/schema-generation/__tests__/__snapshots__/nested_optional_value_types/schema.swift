// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let array: [String?]?
  
    private enum CodingKeys: String, CodingKey {
      case array = "array"
    }
  
    public init(
        array: [String?]? = nil
    ) {
      self.array = array
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      array = try container.decodeIfPresent([String?]?.self, forKey: .array)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(array, forKey: .array)
    }
  }}
