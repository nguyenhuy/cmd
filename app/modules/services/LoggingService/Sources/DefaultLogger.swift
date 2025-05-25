// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import OSLog
import Sentry
import ThreadSafe

// MARK: - DefaultLogger

@ThreadSafe
public final class DefaultLogger: LoggingServiceInterface.Logger {
  public init(subsystem: String, category: String, fileManager: FileManagerI, startSentry _: Bool = true) {
    logger = os.Logger(subsystem: subsystem, category: category)
    self.subsystem = subsystem
    self.category = category
    self.fileManager = fileManager

    SentrySDK.start { options in
      options.dsn = "https://010dbc05cddb56d4795120317831f881@o4509381911576576.ingest.us.sentry.io/4509381913018368"
      options.attachStacktrace = true
      options.enableWatchdogTerminationTracking = true

      // Don't adds IP for users.
      options.sendDefaultPii = false
    }
  }

  deinit {
    logFile?.closeFile()
  }

  public let subsystem: String
  public let category: String

  public func startFileLogging() {
    let wasEnable = _internalState.set(\.isFileLoggingEnabled, to: true)
    guard !wasEnable else { return }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd__HH-mm-ss.SSS"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    let timestamp = dateFormatter.string(from: Date())

    let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let logDir = applicationSupport.appendingPathComponent("XCompanion.\(subsystem)").appendingPathComponent("logs")
    try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)

    let logFilePath = logDir.appendingPathComponent("\(timestamp).\(subsystem).txt")
    do {
      try fileManager.write(data: Data(), to: logFilePath)
      let logFile = try fileManager.fileHandle(forWritingTo: logFilePath)
      inLock { state in
        state.logFile = logFile
      }
    } catch {
      self.error("Error creating log file", error)
    }
  }

  public func subLogger(subsystem: String) -> LoggingServiceInterface.Logger {
    let subsystem = "\(self.subsystem).\(subsystem)"
    let logger = DefaultLogger(subsystem: subsystem, category: category, fileManager: fileManager, startSentry: false)
    if isFileLoggingEnabled {
      logger.startFileLogging()
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

    SentrySDK.capture(message: message)
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
    SentrySDK.capture(error: error)
  }

  private let fileManager: FileManagerI

  private var isFileLoggingEnabled = false

  /// Current log file URL, created with timestamp for each session
  private var logFile: FileHandle?

  /// Queue for handling concurrent write operations to the log file
  private let fileWriteQueue = TaskQueue<Void, any Error>()

  private let logger: os.Logger

  /// Writes a message to the log file
  private func writeToFile(_ message: String) {
    let formattedMessage = "\(Date().ISO8601Format()) \(message)\n"
    guard let logFile, let data = formattedMessage.data(using: .utf8) else { return }
    fileWriteQueue.queue {
      logFile.write(data)
    }
  }
}
