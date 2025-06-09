// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import ServerServiceInterface
import SwiftUI

#if DEBUG
let url = URL(filePath: "/path/to/some-file.txt")

typealias SearchFilesStatus = SearchFilesTool.Use.Status

#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.running),
        input: SearchFilesTool.Input(
          directoryPath: "/path/to/dir",
          regex: "ENV_KEY*",
          filePattern: nil)))

      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.notStarted),
        input: SearchFilesTool.Input(
          directoryPath: "/path/to/dir",
          regex: "ENV_KEY*",
          filePattern: nil)))

      ToolUseView(toolUse: ToolUseViewModel(
        status: SearchFilesStatus.Just(.completed(.success(SearchFilesTool.Use.Output(
          outputForLLm: "...",
          results: [
            Schema.SearchFileResult(
              path: "/path/to/dir/file.swift",
              searchResults: [
                .init(line: 3, text: "ENV_KEY_FOO", isMatch: true),
              ]),
          ],
          rootPath: "/path/to",
          hasMore: false)))),
        input: SearchFilesTool.Input(
          directoryPath: "/path/to/dir",
          regex: "ENV_KEY*",
          filePattern: nil)))
    }
  }
  .frame(minWidth: 200, minHeight: 500)
  .padding()
}
#endif
