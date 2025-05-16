// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import DependencyFoundation
import Foundation
import LoggingServiceInterface
import ShellServiceInterface

// MARK: - DefaultShellService

import ThreadSafe

// MARK: - DefaultShellService

@ThreadSafe
final class DefaultShellService: ShellService {

  init() {
    Task.detached { [weak self] in
      self?.env = try Self.loadZshEnvironment()
    }
  }

  @discardableResult
  func run(
    _ command: String,
    cwd: String?,
    useInteractiveShell: Bool,
    handleStdoutStream: (@Sendable (AsyncStream<Data>) -> Void)? = nil,
    handleSterrStream: (@Sendable (AsyncStream<Data>) -> Void)? = nil)
    async throws -> CommandExecutionResult
  {
    let process = Process()
    process.launchPath = "/bin/zsh"
    if useInteractiveShell {
      process.environment = env
    }
    process.arguments = ["-c"] + [command]
    if let cwd {
      process.currentDirectoryPath = cwd
    }

    let stdin = Pipe()
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr

    let stdoutData = Atomic(Data())
    let stderrData = Atomic(Data())

    let (stdoutStream, stdoutContinuation) = AsyncStream<Data>.makeStream()
    handleStdoutStream?(stdoutStream)
    let (stderrStream, stderrContinuation) = AsyncStream<Data>.makeStream()
    handleSterrStream?(stderrStream)

    Task {
      for await data in stdout.fileHandleForReading.dataStream {
        stdoutData.mutate { $0.append(data) }
        stdoutContinuation.yield(data)
      }
      stdoutContinuation.finish()
    }

    Task {
      for await data in stderr.fileHandleForReading.dataStream {
        stderrData.mutate { $0.append(data) }
        stderrContinuation.yield(data)
      }
      stderrContinuation.finish()
    }

    return try await withCheckedThrowingContinuation { continuation in
      process.terminationHandler = { process in
        let terminationStatus = process.terminationStatus

        let result = CommandExecutionResult(
          exitCode: terminationStatus,
          stdout: String(data: stdoutData.value, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
          stderr: String(data: stderrData.value, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines))

        if result.stderr?.isEmpty == false {
          defaultLogger.error("Error running \(command): \(result.stderr ?? "")")
        }
        continuation.resume(returning: result)
      }

      do {
        try process.run()
      } catch {
        defaultLogger.error("Error running \(command): \(error)")
        continuation.resume(throwing: error)
        return
      }
    }
  }

  private var env: [String: String] = [:]

  private static func loadZshEnvironment(userEnv: [String: String]? = nil) throws -> [String: String] {
    // Load shell environment as base
    let shellProcess = Process()
    shellProcess.executableURL = URL(filePath: "/bin/zsh")

    // Set process environment - either use userEnv if it exists and isn't empty, or use system environment
    if let env = userEnv, !env.isEmpty {
      shellProcess.environment = env
    } else {
      shellProcess.environment = ProcessInfo.processInfo.environment
    }

    shellProcess.arguments = ["-ilc", "printenv"]

    let outputPipe = Pipe()
    shellProcess.standardOutput = outputPipe
    shellProcess.standardError = Pipe()

    try shellProcess.run()
    shellProcess.waitUntilExit()

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    guard let outputString = String(data: data, encoding: .utf8) else {
      defaultLogger.error("Failed to read environment from shell.")
      return ProcessInfo.processInfo.environment
    }

    // Parse shell environment
    return outputString
      .split(separator: "\n")
      .reduce(into: [String: String]()) { result, line in
        let components = line.split(separator: "=", maxSplits: 1)
        guard components.count == 2 else { return }
        result[String(components[0])] = String(components[1])
      }
  }
}

extension BaseProviding {
  public var shellService: ShellService {
    shared {
      DefaultShellService()
    }
  }
}

extension FileHandle {
  public var dataStream: AsyncStream<Data> {
    let (stream, continuation) = AsyncStream<Data>.makeStream()

    readabilityHandler = { handle in
      let data = handle.availableData

      if data.isEmpty {
        handle.readabilityHandler = nil
        continuation.finish()
        return
      }

      continuation.yield(data)
    }

    return stream
  }
}
