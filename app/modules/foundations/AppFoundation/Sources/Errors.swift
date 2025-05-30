// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - AppError

public struct AppError: LocalizedError {
  public init(message: String, debugDescription: String? = nil) {
    self.message = message
    _debugDescription = debugDescription
  }

  public init(_ error: Error) {
    self.init(message: error.localizedDescription, debugDescription: (error as CustomDebugStringConvertible).debugDescription)
  }

  public init(_ message: String) {
    self.init(message: message, debugDescription: nil)
  }

  public let message: String
  private let _debugDescription: String?
}

extension AppError {
  public var errorDescription: String? {
    message
  }
}

// MARK: CustomNSError

extension AppError: CustomNSError {
  public var errorUserInfo: [String: Any] {
    [
      NSLocalizedDescriptionKey: message,
    ]
  }
}

// MARK: CustomDebugStringConvertible

extension AppError: CustomDebugStringConvertible {
  public var debugDescription: String {
    _debugDescription ?? ""
  }
}
