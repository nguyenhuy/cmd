// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - BaseProviding

public protocol BaseProviding: Sendable {
  func _shared<T: Sendable>(key: String, _ build: @Sendable () -> T) -> T
}

extension BaseProviding {
  public func shared<T: Sendable>(key: String = #function, _ build: @Sendable () -> T) -> T {
    _shared(key: key, build)
  }
}
