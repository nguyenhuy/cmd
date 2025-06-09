// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation
import JSONFoundation

// MARK: - Schema

public enum Schema { }

extension KeyedDecodingContainer {
  /// Sugar syntax for decoding optional values without changing the type to be non optional.
  func decodeIfPresent<T: Decodable>(_ type: T?.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
    if contains(key) {
      return try decode(type, forKey: key)
    }
    return nil
  }
}
