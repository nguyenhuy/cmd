// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

#if DEBUG
let url = URL(filePath: "/path/to/some-directory")
#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      ToolUseView(toolUse: ToolUseViewModel(status: .Just(.running), directoryPath: url))
      ToolUseView(toolUse: ToolUseViewModel(status: .Just(.notStarted), directoryPath: url))
      ToolUseView(toolUse: ToolUseViewModel(
        status: .Just(.completed(.success(.init(
          files: [
            .init(path: "fileA.swift", attr: "-rw-r--r--", size: "10 KB"),
            .init(path: "fileB.sh", attr: "-rwxr-xr-x", size: "1 KB"),
            .init(path: "subdirectory", attr: "drwxr-xr-x", size: "0.2 KB"),
          ],
          hasMore: false)))),
        directoryPath: url))
    }
  }
  .frame(minWidth: 200, minHeight: 500)
  .padding()
}
#endif
