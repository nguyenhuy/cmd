// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation

// MARK: - FileSuggestion

public struct FileSuggestion: Sendable, Equatable {
  public let path: URL
  public let displayPath: String
  public let matchedRanges: [ClosedRange<Int>]

  public init(path: URL, displayPath: String, matchedRanges: [ClosedRange<Int>]) {
    self.path = path
    self.displayPath = displayPath
    self.matchedRanges = matchedRanges
  }
}

// MARK: Identifiable

extension FileSuggestion: Identifiable {
  public var id: URL {
    path
  }
}

// MARK: - FileSuggestionService

public protocol FileSuggestionService: Sendable {
  func suggestFiles(
    for query: String,
    in workspace: URL,
    top: Int)
    async throws -> [FileSuggestion]
}

// MARK: - FileSuggestionServiceProviding

public protocol FileSuggestionServiceProviding {
  var fileSuggestionService: FileSuggestionService { get }
}
