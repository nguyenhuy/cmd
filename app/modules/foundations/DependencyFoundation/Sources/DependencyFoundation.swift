// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
