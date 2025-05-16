// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct Wrapper: Codable, Sendable {
    public let properties: JSON
  
    private enum CodingKeys: String, CodingKey {
      case properties = "properties"
    }
  
    public init(
        properties: JSON
    ) {
      self.properties = properties
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      properties = try container.decode(JSON.self, forKey: .properties)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(properties, forKey: .properties)
    }
  }}
