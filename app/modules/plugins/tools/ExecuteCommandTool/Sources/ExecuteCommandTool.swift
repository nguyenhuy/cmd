// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Dependencies
import Foundation
import JSONFoundation
import ShellServiceInterface
import ToolFoundation

// MARK: - ExecuteCommandTool

public final class ExecuteCommandTool: NonStreamableTool {
  public init() { }

  // TODO: remove @unchecked Sendable once https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed.
  public final class Use: ToolUse, @unchecked Sendable {

    init(callingTool: ExecuteCommandTool, toolUseId: String, input: Input, context: ToolExecutionContext) {
      self.callingTool = callingTool
      self.toolUseId = toolUseId
      self.context = context
      self.input = Input(
        command: input.command,
        cwd: input.cwd.map { $0.resolvePath(from: context.projectRoot).path() },
        canModifySourceFiles: input.canModifySourceFiles,
        canModifyDerivedFiles: input.canModifyDerivedFiles)

      let (stream, updateStatus) = Status.makeStream(initial: .notStarted)
      status = stream
      self.updateStatus = updateStatus

      let (stdout, setStdout) = Future<BroadcastedStream<Data>, Never>.make()
      stdoutStream = stdout
      setStdoutStream = { stream in setStdout(.success(stream)) }
      let (stderr, setStderr) = Future<BroadcastedStream<Data>, Never>.make()
      stderrStream = stderr
      setStderrStream = { stream in setStderr(.success(stream)) }
    }

    public struct Input: Codable, Sendable {
      public let command: String
      public let cwd: String?
      public let canModifySourceFiles: Bool
      public let canModifyDerivedFiles: Bool
    }

    public struct Output: Codable, Sendable {
      public let stdout: String?
      public let stderr: String?
      public let exitCode: Int32
    }

    // TODO: add support for readonly uses of the terminal.
    public let isReadonly = false

    public let callingTool: ExecuteCommandTool
    public let toolUseId: String
    public let input: Input

    public let status: Status

    public func startExecuting() {
      updateStatus.yield(.running)

      Task {
        do {
          let shellResult = try await shellService.run(
            input.command,
            cwd: input.cwd ?? context.projectRoot?.path(),
            useInteractiveShell: true,
            handleStdoutStream: { stream in self.setStdoutStream(.init(stream)) },
            handleSterrStream: { stream in self.setStderrStream(.init(stream)) })
          if shellResult.exitCode == 0 {
            updateStatus.yield(.completed(.success(Output(
              stdout: shellResult.stdout,
              stderr: shellResult.stderr,
              exitCode: shellResult.exitCode))))
          } else {
            try updateStatus
              .yield(
                .completed(
                  .failure(
                    AppError(
                      "The command failed.\(String(data: JSONEncoder().encode(shellResult), encoding: .utf8) ?? "")"))))
          }
        } catch {
          updateStatus.yield(.completed(.failure(error)))
        }
      }
    }

    let stdoutStream: Future<BroadcastedStream<Data>, Never>
    let stderrStream: Future<BroadcastedStream<Data>, Never>

    let setStdoutStream: (BroadcastedStream<Data>) -> Void
    let setStderrStream: (BroadcastedStream<Data>) -> Void

    @Dependency(\.shellService) private var shellService

    private let context: ToolExecutionContext
    private let updateStatus: AsyncStream<ToolUseExecutionStatus<Output>>.Continuation

  }

  public let name = "execute_command"
  
  public var displayName: String {
    "Execute Command"
  }

  public let description = """
    Request to execute a CLI command on the system. Use this when you need to perform system operations or run specific commands to accomplish any step in the user's task. You must tailor your command to the user's system and provide a clear explanation of what the command does. For command chaining, use the appropriate chaining syntax for the user's shell. Prefer to execute complex CLI commands over creating executable scripts, as they are more flexible and easier to run. Prefer relative commands and paths that avoid location sensitivity for terminal consistency, e.g: `touch ./testdata/example.file`, `dir ./examples/model1/data/yaml`, or `swift test ./cmd/package`. If directed by the user, you may open a terminal in a different directory by using the `cwd` parameter.
    DO NOT use this to create or update files. Instead describe them as code suggestions, and wait for the users to approve the changes.
    """

  public var inputSchema: JSON {
    .object([
      "type": .string("object"),
      "properties": .object([
        "command": .object([
          "type": .string("string"),
          "description": .string("The command to execute."),
        ]),
        "cwd": .object([
          "type": .string("string"),
          "description": .string("Only if absolutely necessary, the directory in which to execute the command."),
        ]),
        "canModifySourceFiles": .object([
          "type": .string("boolean"),
          "description": .string("Whether the command can modify files tracked by the source control system."),
        ]),
        "canModifyDerivedFiles": .object([
          "type": .string("boolean"),
          "description": .string("Whether the command can modify derived files that are unlikely to be tracked by the source control system. For instance `swift build` generates derived files but doesn't modify source files."),
        ]),
      ]),
      "required": .array([
        .string("command"),
        .string("canModifySourceFiles"),
        .string("canModifyDerivedFiles"),
      ]),
    ])
  }

  public func isAvailable(in mode: ChatMode) -> Bool {
    // TODO: add support for readonly uses of the terminal.
    mode == .agent
  }

  public func use(toolUseId: String, input: Use.Input, context: ToolExecutionContext) -> Use {
    Use(callingTool: self, toolUseId: toolUseId, input: input, context: context)
  }

}

// MARK: - ToolUseViewModel

@Observable
@MainActor
final class ToolUseViewModel {

  init(
    command: String,
    status: ExecuteCommandTool.Use.Status,
    stdout: Future<BroadcastedStream<Data>, Never>,
    stderr: Future<BroadcastedStream<Data>, Never>)
  {
    self.command = command
    self.status = status.value
    Task {
      for await status in status {
        self.status = status
      }
    }
    Task {
      let stdoutStream = await stdout.value
      for await data in stdoutStream {
        self.stdData += data
        self.std = String(data: stdData, encoding: .utf8)
      }
    }
    Task {
      let stderrStream = await stderr.value
      for await data in stderrStream {
        self.stdData += data
        self.std = String(data: stdData, encoding: .utf8)
      }
    }
  }

  let command: String
  var status: ToolUseExecutionStatus<ExecuteCommandTool.Use.Output>
  var std: String?
  var stdData = Data()
}
