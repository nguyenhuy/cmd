// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation
import ThreadSafe

#if DEBUG
// MARK: - MockShellService

@ThreadSafe
public final class MockShellService: ShellService {

  public init() { }

  public var onRun: (
    @Sendable (String, String?, Bool, SubprocessHandle?) async throws
      -> CommandExecutionResult) = {
    _, _, _, _ in
    CommandExecutionResult(exitCode: 0)
  }

  public func run(
    _ command: String,
    cwd: String?,
    useInteractiveShell: Bool,
    body: SubprocessHandle? = nil)
    async throws -> CommandExecutionResult
  {
    try await onRun(command, cwd, useInteractiveShell, body)
  }
}
#endif
