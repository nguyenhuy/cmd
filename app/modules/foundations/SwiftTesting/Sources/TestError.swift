// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

public struct TestError: Error {
  public init(_ message: String) {
    self.message = message
  }

  public let message: String
}
