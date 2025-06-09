// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import FileDiffFoundation
import Foundation

// MARK: - ExtensionCommandKeys

public enum ExtensionCommandKeys {
  public static let openInCursor = "openInCursor"
  public static let getFileChangeToApply = "getFileChangeToApply"
  public static let confirmFileChangeApplied = "confirmFileChangeApplied"
}

// MARK: - ExtensionTimeout

public enum ExtensionTimeout {
  public static let applyFileChangeTimeout: TimeInterval = 2
}

// MARK: - ExtensionCommandNames

public enum ExtensionCommandNames {
  public static let applyEdit = "Apply Edit"
}

// MARK: - FileChangeConfirmation

public struct FileChangeConfirmation: Codable, Sendable {
  public let id: String
  public let error: String?

  public init(id: String, error: String?) {
    self.id = id
    self.error = error
  }
}

// MARK: - EmptyInput

public struct EmptyInput: Codable {
  public init() { }
}

// MARK: - EmptyResponse

public struct EmptyResponse: Codable, Sendable {
  public init() { }
}

// MARK: - ExtensionRequest

public struct ExtensionRequest<Input: Codable>: Codable {
  public let type = "execute-command"
  public let command: String
  public let input: Input

  public init(command: String, input: Input) {
    self.command = command
    self.input = input
  }

  public init(from decoder: any Decoder) throws {
    let container: KeyedDecodingContainer<ExtensionRequest<Input>.CodingKeys> = try decoder
      .container(keyedBy: ExtensionRequest<Input>.CodingKeys.self)
    command = try container.decode(String.self, forKey: ExtensionRequest<Input>.CodingKeys.command)
    input = try container.decode(Input.self, forKey: ExtensionRequest<Input>.CodingKeys.input)
  }
}

// MARK: - SharedKeys

public enum SharedKeys {
  public static let pointReleaseXcodeExtensionToDebugApp = "pointReleaseXcodeExtensionToDebugApp"
}
