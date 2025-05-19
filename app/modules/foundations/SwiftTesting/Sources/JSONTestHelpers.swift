// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Foundation
import Testing

extension Data {
  public func jsonString() -> String {
    do {
      let object = try JSONSerialization.jsonObject(with: self, options: [])
      let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
      guard let string = String(data: data, encoding: .utf8) else {
        throw TestError("Invalid JSON data")
      }
      return string
    } catch {
      Issue.record(error)
      return ""
    }
  }

  public func expectToMatch(_ expected: String) {
    let expectedData = expected.utf8Data
    #expect(jsonString() == expectedData.jsonString())
  }
}

/// Test decoding the Json data to the given type, encoding it back to Json, and comparing the results.
public func testDecodingEncodingOf<T: Codable>(_ json: String, with _: T.Type) throws {
  let jsonData = json.utf8Data
  let jsonDecoder = JSONDecoder()
  let decoded = try jsonDecoder.decode(T.self, from: jsonData)

  let encoder = JSONEncoder()
  let encoded = try encoder.encode(decoded)

  let value = encoded.jsonString()
  let expected = jsonData.jsonString()

  #expect(expected == value)
}

/// Test that encoding the value gives the expected json.
public func testEncoding(_ value: some Encodable, _ json: String) throws {
  let encoded = try JSONEncoder().encode(value)
  let encodedString = encoded.jsonString()

  // Reformat the json expectation (pretty print, sort keys)
  let jsonData = json.utf8Data
  let expected = jsonData.jsonString()

  #expect(expected == encodedString)
}

/// Test that decoding the json gives the expected value.
public func testDecoding<T: Decodable & Equatable>(_ value: T, _ json: String) throws {
  let decoded = try JSONDecoder().decode(T.self, from: json.utf8Data)
  #expect(decoded == value)
}

/// Test that encoding the value gives the expected json, and that decoding the json gives the expected value.
public func testEncodingDecoding(_ value: some Codable & Equatable, _ json: String) throws {
  try testEncoding(value, json)
  try testDecoding(value, json)
}
