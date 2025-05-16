// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
    let xcodeExtensionPrefix = "Xcompanion error: "
    let localizedDescription = message.hasPrefix(xcodeExtensionPrefix) ? message : "\(xcodeExtensionPrefix)\(message)"

    return [
      NSLocalizedDescriptionKey: localizedDescription,
    ]
  }
}
