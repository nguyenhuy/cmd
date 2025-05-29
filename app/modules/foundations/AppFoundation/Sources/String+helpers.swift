// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

extension String {
  public var utf8Data: Data {
    Data(utf8)
  }
}

extension String: @retroactive CodingKey {

  public init?(stringValue: String) {
    self = stringValue
  }

  public init?(intValue: Int) {
    self = "\(intValue)"
  }

  public var stringValue: String { self }
  public var intValue: Int? { Int(self) }
}
