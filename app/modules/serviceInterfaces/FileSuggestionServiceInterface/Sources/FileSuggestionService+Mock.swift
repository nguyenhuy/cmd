// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import ThreadSafe

@ThreadSafe
public final class MockFileSuggestionService: FileSuggestionService {

  public init(suggestions: [FileSuggestion] = []) {
    self.suggestions = suggestions
    _onSuggestFiles = { _, _, _ in
      suggestions
    }
  }

  public var onSuggestFiles: @Sendable (String, URL, Int) -> [FileSuggestion] {
    get { _onSuggestFiles }
    set { _onSuggestFiles = newValue }
  }

  public func suggestFiles(
    for query: String,
    in root: URL,
    top: Int = 5)
    async throws -> [FileSuggestion]
  {
    _onSuggestFiles(query, root, top)
  }

  private let suggestions: [FileSuggestion]

  private var _onSuggestFiles: @Sendable (String, URL, Int) -> [FileSuggestion]

}
