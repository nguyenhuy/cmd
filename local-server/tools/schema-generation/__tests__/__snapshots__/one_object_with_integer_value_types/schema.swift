// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/schemaFile.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ValueType: Codable, Sendable {
    public let line: Int
    public let column: Int?
  
    private enum CodingKeys: String, CodingKey {
      case line = "line"
      case column = "column"
    }
  
    public init(
        line: Int,
        column: Int? = nil
    ) {
      self.line = line
      self.column = column
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      line = try container.decode(Int.self, forKey: .line)
      column = try container.decodeIfPresent(Int?.self, forKey: .column)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(line, forKey: .line)
      try container.encodeIfPresent(column, forKey: .column)
    }
  }}
