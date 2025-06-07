// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import FileSuggestionServiceInterface
import SwiftUI

#Preview {
  VStack {
    SearchResultsView(
      selectedRowIndex: Binding.constant(0),
      results: [
        FileSuggestion(path: URL(filePath: "/path/to/app/file.swift"), displayPath: "app/file.swift", matchedRanges: []),
        FileSuggestion(
          path: URL(filePath: "/path/to/app/long-file-name.swift"),
          displayPath: "app/long-file-name.swift",
          matchedRanges: []),
        FileSuggestion(
          path: URL(filePath: "/path/to/app/very-very-long-file-name.swift"),
          displayPath: "app/very-very-long-file-name.swift",
          matchedRanges: []),
      ])
    Spacer()

    SearchResultsView(
      selectedRowIndex: Binding.constant(0),
      results: [
        FileSuggestion(path: URL(filePath: "/path/to/app/file.swift"), displayPath: "app/file.swift", matchedRanges: []),

      ],
      searchInput: .constant(""))
  }.frame(width: 200, height: 200)
    .padding(10)
}
