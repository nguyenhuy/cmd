// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppEventServiceInterface
import Foundation
// MARK: - ExecuteExtensionRequestEvent

public struct ExecuteExtensionRequestEvent: AppEvent {

  public init(
    command: String,
    id: String,
    data: Data,
    completion: @escaping @Sendable (Result<any Encodable & Sendable, Error>) -> Void)
  {
    self.command = command
    self.id = id
    self.data = data
    self.completion = completion
  }

  public let command: String
  public let id: String
  public let data: Data
  public let completion: @Sendable (Result<any Encodable & Sendable, Error>) -> Void
}
