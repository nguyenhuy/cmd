// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CodePreview
import DLS
import FileDiffFoundation
import FileDiffTypesFoundation
import Foundation
import ServerServiceInterface
import SwiftUI
import ToolFoundation

#if DEBUG
// MARK: - Preview Provider

struct FileChangeView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Preview collapsed state
      FileChangeView(change: mockFileDiffViewModel, editState: .applied)
        .frame(width: 500)
        .preferredColorScheme(.dark)
        .previewDisplayName("Collapsed State")

      // Preview expanded state (pre-expanded)
      FileChangeView(change: mockFileDiffViewModel, editState: .rejected, initiallyExpanded: true)
        .frame(width: 500, height: 600)
        .preferredColorScheme(.dark)
        .previewDisplayName("Expanded State")

      // Error state
      FileChangeView(change: mockFileDiffViewModel, editState: .error("Could not apply file change."))
        .frame(width: 500)
        .preferredColorScheme(.dark)
        .previewDisplayName("Error State")
    }
    .padding()
    .background(Color.black)
  }

  /// Mock data for previews
  static var mockFileDiffViewModel: FileDiffViewModel {
    let filePath = URL(string: "file:///Users/user/Project/WindowInfo.swift")!
    let baseContent = """
      import Foundation

      struct WindowInfo {
          let id: String
          let title: String

          func describe() -> String {
              return "Window \\(id): \\(title)"
          }
      }
      """

    let targetContent = """
      import Foundation
      import AppKit

      struct WindowInfo: Identifiable {
          let id: String
          let title: String
          var isActive: Bool = false

          func describe() -> String {
              let status = isActive ? "active" : "inactive"
              return "Window \\(id): \\(title) (\\(status))"
          }
      }
      """

    let changes: [FileDiff.SearchReplace] = [
      .init(search: "import Foundation", replace: "import Foundation\nimport AppKit"),
      .init(search: "struct WindowInfo {", replace: "struct WindowInfo: Identifiable {"),
      .init(
        search: "    let id: String\n    let title: String",
        replace: "    let id: String\n    let title: String\n    var isActive: Bool = false"),
      .init(
        search: "    func describe() -> String {\n        return \"Window \\(id): \\(title)\"\n    }",
        replace: "    func describe() -> String {\n        let status = isActive ? \"active\" : \"inactive\"\n        return \"Window \\(id): \\(title) (\\(status))\"\n    }"),
    ]

    return FileDiffViewModel(
      filePath: filePath,
      baseLineContent: baseContent,
      targetContent: targetContent,
      changes: changes,
      canBeApplied: true,
      formattedDiff: nil // Setting to nil to test the fallback in our extension
    )
  }
}
#endif
