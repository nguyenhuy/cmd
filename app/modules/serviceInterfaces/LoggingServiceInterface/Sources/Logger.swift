// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import OSLog

// MARK: - Logger

public struct Logger: Sendable {

  init(subsystem: String, category: String) {
    logger = os.Logger(subsystem: subsystem, category: category)
    self.subsystem = subsystem
    self.category = category
  }

  public func subLogger(subsystem: String) -> Logger {
    let subsystem = "\(self.subsystem).\(subsystem)"
    return Logger(subsystem: subsystem, category: category)
  }

  public func debug(_ message: String) {
    logger.debug("[Debug] \(message, privacy: .public)")
  }

  public func info(_ message: String) {
    logger.info("[Info] \(message, privacy: .public)")
  }

  public func log(_ message: String) {
    logger.log("[Log] \(message, privacy: .public)")
  }

  public func notice(_ message: String) {
    logger.notice("[Notice] \(message, privacy: .public)")
  }

  public func error(_ message: String) {
    logger.error("[Error] \(message, privacy: .public)")
  }

  private let subsystem: String
  private let category: String

  private let logger: os.Logger

}

/// Default logger than can be used throughout the app.
public let defaultLogger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
  category: "Xcompanion")
