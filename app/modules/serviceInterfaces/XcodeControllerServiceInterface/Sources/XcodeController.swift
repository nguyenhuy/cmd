// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@_exported import FileDiffTypesFoundation
import Foundation

// MARK: - XcodeController

public protocol XcodeController: Sendable {
  func apply(fileChange: FileChange) async throws
  func build(project: URL, buildType: BuildType) async throws -> BuildSection
}

// MARK: - XcodeControllerProviding

public protocol XcodeControllerProviding {
  var xcodeController: XcodeController { get }
}

// MARK: - BuildType

public enum BuildType: String, Codable, Sendable {
  case test
  case run
}

// MARK: - BuildError

public struct BuildError: Error {
  public let exitCode: Int
  public let output: String

  public init(exitCode: Int, output: String) {
    self.exitCode = exitCode
    self.output = output
  }
}

// MARK: - BuildSection

public struct BuildSection: Codable, Sendable {
  public init(title: String, messages: [BuildMessage], subSections: [BuildSection], duration: TimeInterval) {
    self.title = title
    self.messages = messages
    self.subSections = subSections
    self.duration = duration

    var maxSeverity = BuildMessage.Severity.info
    for message in messages {
      if message.severity.rawValue > maxSeverity.rawValue {
        maxSeverity = message.severity
      }
    }
    for section in subSections {
      let sectionSeverity = section.maxSeverity
      if sectionSeverity.rawValue > maxSeverity.rawValue {
        maxSeverity = sectionSeverity
      }
    }
    self.maxSeverity = maxSeverity
  }

  public let title: String
  public let messages: [BuildMessage]
  public let subSections: [BuildSection]
  public let duration: TimeInterval
  public let maxSeverity: BuildMessage.Severity

}

// MARK: - BuildMessage

public struct BuildMessage: Codable, Sendable {
  public init(message: String, severity: Severity, location: Location?) {
    self.message = message
    self.severity = severity
    self.location = location
  }

  public enum Severity: Int, Codable, Sendable, RawRepresentable {
    case info = 0
    case warning = 1
    case error = 2
  }

  public struct Location: Codable, Sendable {
    public init(
      file: URL,
      startingLineNumber: Int?,
      startingColumnNumber: Int?,
      endingLineNumber: Int?,
      endingColumnNumber: Int?)
    {
      self.file = file
      self.startingLineNumber = startingLineNumber
      self.startingColumnNumber = startingColumnNumber
      self.endingLineNumber = endingLineNumber
      self.endingColumnNumber = endingColumnNumber
    }

//        location = 0x00006000001e51a0 {
//          XCLogParser.DVTDocumentLocation = {
//            documentURLString = "file:///Users/guigui/dev/Xcompanion/app/modules/services/XcodeControllerService/Sources/DefaultXcodeController+build.swift"
//            timestamp = 769646409.20149696
//          }
//          startingLineNumber = 77
//          startingColumnNumber = 10
//          endingLineNumber = 77
//          endingColumnNumber = 10
    public let file: URL
    public let startingLineNumber: Int?
    public let startingColumnNumber: Int?
    public let endingLineNumber: Int?
    public let endingColumnNumber: Int?

  }

  public let message: String
  public let severity: Severity
  public let location: Location?

}
