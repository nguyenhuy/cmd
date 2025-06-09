// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Foundation

// MARK: - XcodeExtensionError

public struct XcodeExtensionError: Error {
  let message: String
}

extension XcodeExtensionError {
  public init(_ underlyingError: Error) {
    self.init(message: underlyingError.localizedDescription)
  }
}

// MARK: CustomNSError

extension XcodeExtensionError: CustomNSError {
  public var errorUserInfo: [String: Any] {
    let xcodeExtensionPrefix = "command error: "
    let localizedDescription = message.hasPrefix(xcodeExtensionPrefix) ? message : "\(xcodeExtensionPrefix)\(message)"

    return [
      NSLocalizedDescriptionKey: localizedDescription,
    ]
  }
}
