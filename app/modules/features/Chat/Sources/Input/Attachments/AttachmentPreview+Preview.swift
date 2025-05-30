// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SwiftUI
// MARK: - Preview Helpers

#if DEBUG
let mediumFileContent = """
  // 1
  // 2
  // 3
  struct CodePreview: View {
    let filePath: URL
    let fileContent: String
    let startLine: Int?
    let endLine: Int?

    var body: some View {
      Text(content)
    }
  }
  // 14
  // 15
  """

let shortFileContent = """
    var body: some View {
      Text(content) // some very very very very very long comment
    }
  """

#Preview {
  VStack(alignment: .leading, spacing: 10) {
    VStack {
      AttachmentPreview(attachment: .image(.init(imageData: imageData, path: nil)))
      Spacer()
    }
    .frame(height: 50)
    AttachmentPreview(attachment: .buildError(.init(
      message: "Error!",
      filePath: URL(filePath: "/Users/me/app/source.swift")!,
      line: 4,
      column: 3)))
  }
  .frame(width: 400)
  .padding(10)
  .background(ColorScheme.dark.secondarySystemBackground)
}
#endif
