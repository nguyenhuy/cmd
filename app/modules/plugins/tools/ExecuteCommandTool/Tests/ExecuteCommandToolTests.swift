// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import Foundation
import LLMServiceInterface
import ServerServiceInterface
import ShellServiceInterface
import SwiftTesting
import Testing
@testable import ExecuteCommandTool

struct ExecuteCommandToolTests {
  @Test
  func completesWithTheExpectedOutcome() async throws {
    let shellService = MockShellService()
    shellService.onRun = { command, cwd, useInteractiveShell, _, _ in
      #expect(command == "ls -la")
      #expect(cwd == "/path/to/root/path/to/dir")
      #expect(useInteractiveShell == true)
      return CommandExecutionResult(
        exitCode: 0,
        stdout: "file.txt",
        stderr: "")
    }

    let llmService = MockLLMService()
    llmService.onResolve = { path in
      URL(filePath: "/path/to/root").appending(path: path)
    }

    let toolUse = withDependencies {
      $0.shellService = shellService
      $0.llmService = llmService
    } operation: {
      let toolUse = ExecuteCommandTool().use(
        toolUseId: "123",
        input: .init(
          command: "ls -la",
          cwd: "./path/to/dir",
          canModifySourceFiles: false,
          canModifyDerivedFiles: false),
        context: .init(projectRoot: URL(filePath: "/path/to/root")))
      toolUse.startExecuting()
      return toolUse
    }
    let result = try await toolUse.result
    #expect(result.exitCode == 0)
    #expect(result.stdout == "file.txt")
    #expect(result.stderr == "")
  }

  @Test
  func completesWithAFailureWhenSomethingWentWrong() async throws {
    let shellService = MockShellService()
    shellService.onRun = { _, _, _, _, _ in
      struct ShellError: Error {
        let message: String
      }
      throw ShellError(message: "Command failed")
    }
    let llmService = MockLLMService()
    llmService.onResolve = { path in
      URL(filePath: "/path/to/root").appending(path: path)
    }

    let toolUse = withDependencies {
      $0.shellService = shellService
      $0.llmService = llmService
    } operation: {
      let toolUse = ExecuteCommandTool().use(
        toolUseId: "123",
        input: .init(
          command: "ls -la",
          cwd: "./path/to/dir",
          canModifySourceFiles: false,
          canModifyDerivedFiles: false),
        context: .init(projectRoot: URL(filePath: "/path/to/root")))
      toolUse.startExecuting()
      return toolUse
    }
    await #expect(throws: Error.self, performing: {
      try await toolUse.result
    })
  }
}
