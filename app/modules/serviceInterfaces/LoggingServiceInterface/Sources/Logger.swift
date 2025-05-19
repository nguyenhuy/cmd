// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import FoundationInterfaces
import OSLog
import ThreadSafe

// MARK: - Logger

@ThreadSafe
public final class Logger: Sendable {
  init(subsystem: String, category: String) {
    logger = os.Logger(subsystem: subsystem, category: category)
    self.subsystem = subsystem
    self.category = category
  }

  deinit {
    logFile?.closeFile()
  }

  public func startFileLogging(fileManager: FileManagerI) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd__HH-mm-ss.SSS"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    let timestamp = dateFormatter.string(from: Date())

    let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let logDir = applicationSupport.appendingPathComponent("XCompanion").appendingPathComponent("logs")
    try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)

    let logFilePath = logDir.appendingPathComponent("\(timestamp).\(subsystem).txt")
    do {
      try fileManager.write(data: Data(), to: logFilePath)
      let logFile = try fileManager.fileHandle(forWritingTo: logFilePath)
      safelyMutate { state in
        state.logFile = logFile
        state.fileManager = fileManager
      }
    } catch {
      self.error("Error creating log file", error)
    }
  }

  public func subLogger(subsystem: String) -> Logger {
    let subsystem = "\(self.subsystem).\(subsystem)"
    let logger = Logger(subsystem: subsystem, category: category)
    if let fileManager {
      logger.startFileLogging(fileManager: fileManager)
    }
    return logger
  }

  public func debug(_ message: String) {
    let formattedMessage = "[Debug] \(message)"
    logger.debug("\(formattedMessage, privacy: .public)")
    writeToFile("\(subsystem).\(category) \(formattedMessage)")
  }

  public func info(_ message: String) {
    let formattedMessage = "[Info] \(message)"
    logger.info("\(formattedMessage, privacy: .public)")
    writeToFile("\(subsystem).\(category) \(formattedMessage)")
  }

  public func log(_ message: String) {
    let formattedMessage = "[Log] \(message)"
    logger.log("\(formattedMessage, privacy: .public)")
    writeToFile("\(subsystem).\(category) \(formattedMessage)")
  }

  public func notice(_ message: String) {
    let formattedMessage = "[Notice] \(message)"
    logger.notice("\(formattedMessage, privacy: .public)")
    writeToFile("\(subsystem).\(category) \(formattedMessage)")
  }

  public func error(_ message: String) {
    let formattedMessage = "[Error] \(message)"
    logger.error("\(formattedMessage, privacy: .public)")
    writeToFile("\(subsystem).\(category) \(formattedMessage)")
  }

  public func error(_ error: any Error) {
    self.error(nil, error)
  }

  public func error(_ message: String?, _ error: any Error) {
    let messagePrefix = message != nil ? "\(message!): " : ""
    let debugDescription = (error as CustomDebugStringConvertible).debugDescription

    if !debugDescription.isEmpty {
      let formattedMessage = "[Error] \(messagePrefix)\(error.localizedDescription)\n\ndebugDescription: \(debugDescription)"
      logger.error(
        "\(formattedMessage, privacy: .public)")
      writeToFile("\(subsystem).\(category) \(formattedMessage)")
    } else {
      let formattedMessage = "[Error] \(messagePrefix)\(error.localizedDescription)"
      logger.error("\(formattedMessage, privacy: .public)")
      writeToFile("\(subsystem).\(category) \(formattedMessage)")
    }
  }

  /// Current log file URL, created with timestamp for each session
  private var logFile: FileHandle?
  private var fileManager: FileManagerI?

  /// Queue for handling concurrent write operations to the log file
  private let fileWriteQueue = TaskQueue<Void, any Error>()

  private let subsystem: String
  private let category: String

  private let logger: os.Logger

  /// Writes a message to the log file
  private func writeToFile(_ message: String) {
    fileWriteQueue.queue {
      let formattedMessage = "\(Date().ISO8601Format()) \(message)\n"
      guard let logFile = self.logFile, let data = formattedMessage.data(using: .utf8) else { return }

      logFile.write(data)
    }
  }

}

/// Default logger than can be used throughout the app.
public let defaultLogger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
  category: "Xcompanion")
