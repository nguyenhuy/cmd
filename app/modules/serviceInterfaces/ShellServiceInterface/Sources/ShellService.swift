// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import LoggingServiceInterface

// MARK: - CommandExecutionResult

public struct CommandExecutionResult: Equatable, Sendable, Encodable {
  public let exitCode: Int32
  public let stdout: String?
  public let stderr: String?

  public init(exitCode: Int32, stdout: String? = nil, stderr: String? = nil) {
    self.exitCode = exitCode
    self.stdout = stdout
    self.stderr = stderr
  }
}

// MARK: - ShellService

public protocol ShellService: Sendable {
  // MARK: Public

  @discardableResult
  func run(
    _ command: String,
    cwd: String?,
    useInteractiveShell: Bool,
    handleStdoutStream: (@Sendable (AsyncStream<Data>) -> Void)?,
    handleSterrStream: (@Sendable (AsyncStream<Data>) -> Void)?)
    async throws -> CommandExecutionResult
}

extension ShellService {

  @discardableResult
  public func run(
    _ command: String,
    cwd: String? = nil,
    useInteractiveShell: Bool = false)
    async throws -> CommandExecutionResult
  {
    try await run(command, cwd: cwd, useInteractiveShell: useInteractiveShell, handleStdoutStream: nil, handleSterrStream: nil)
  }

  public func stdout(_ command: String, cwd: String? = nil, useInteractiveShell: Bool = false) async throws -> String? {
    let result = try await run(
      command,
      cwd: cwd,
      useInteractiveShell: useInteractiveShell,
      handleStdoutStream: nil,
      handleSterrStream: nil)
    return result.stdout
  }
}

// MARK: - ShellServiceProviding

public protocol ShellServiceProviding {
  var shellService: ShellService { get }
}
