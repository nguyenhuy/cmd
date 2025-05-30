// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import ThreadSafe

#if DEBUG
// MARK: - MockShellService

@ThreadSafe
public final class MockShellService: ShellService {

  public init() { }

  public var onRun: (
    @Sendable (String, String?, Bool, ((AsyncStream<Data>) -> Void)?, ((AsyncStream<Data>) -> Void)?) async throws
      -> CommandExecutionResult) = {
    _, _, _, _, _ in
    CommandExecutionResult(exitCode: 0)
  }

  public func run(
    _ command: String,
    cwd: String?,
    useInteractiveShell: Bool,
    handleStdoutStream: (@Sendable (AsyncStream<Data>) -> Void)?,
    handleSterrStream: (@Sendable (AsyncStream<Data>) -> Void)?)
    async throws -> CommandExecutionResult
  {
    try await onRun(command, cwd, useInteractiveShell, handleStdoutStream, handleSterrStream)
  }
}
#endif
