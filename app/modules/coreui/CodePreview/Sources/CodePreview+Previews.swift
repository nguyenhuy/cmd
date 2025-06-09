// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import DLS
import SwiftUI

// MARK: - Preview Helpers

#if DEBUG
private let mediumFileContent = """
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

private let shortFileContent = """
    var body: some View {
      Text(content) // some very very very very very long comment
    }
  """

#Preview {
  VStack(alignment: .leading, spacing: 10) {
    VStack {
      CodePreview(
        filePath: URL(filePath: "/Users/me/app/source.swift")!,
        startLine: 3,
        endLine: 14,
        content: mediumFileContent)
        .frame(width: 250)
      Spacer(minLength: 0)
    }
    .frame(height: 150)
    VStack {
      CodePreview(
        filePath: URL(filePath: "/Users/me/app/source.swift")!,
        startLine: 3,
        endLine: 14,
        content: mediumFileContent,
        expandedHeight: nil)
        .frame(width: 250)
      Spacer(minLength: 0)
    }
    .frame(height: 250)
    VStack {
      CodePreview(
        filePath: URL(filePath: "/Users/me/app/source.swift")!,
        startLine: nil,
        endLine: nil,
        content: shortFileContent)
      Spacer(minLength: 0)
    }
    .frame(height: 150)
  }
  .frame(width: 400)
  .padding(10)
  .background(ColorScheme.dark.secondarySystemBackground)
}

#endif
