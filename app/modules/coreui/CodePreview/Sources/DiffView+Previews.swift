// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import FileDiffFoundation
import SwiftUI

#if DEBUG
// MARK: - Eventual

@Observable
@MainActor
final class Eventual<Value: Sendable>: Sendable {

  init(task: @escaping @Sendable () async -> Value) {
    Task {
      let value = await task()
      Task { @MainActor in
        self.value = value
      }
    }
  }

  private(set) var value: Value?
}

// MARK: - PreviewHelper

extension FormattedFileChange {
  @MainActor
  var mockSuggestion: FileDiffViewModel {
    FileDiffViewModel(
      filePath: URL(filePath: "/"),
      baseLineContent: "",
      targetContent: "",
      changes: [],
      canBeApplied: true,
      formattedDiff: self)
  }
}

private struct PreviewHelper: View {

  init(oldContent: String, newContent: String) {
    self.oldContent = oldContent
    self.newContent = newContent

    diff = .init(task: {
      try! await FileDiff.getColoredDiff(
        oldContent: oldContent,
        newContent: newContent,
        highlightColors: .dark(.xcode)).mockSuggestion
    })
  }

  let oldContent: String
  let newContent: String

  var body: some View {
    if let diff = diff.value {
      DiffView(change: diff)
    }
  }

  @Bindable private var diff: Eventual<FileDiffViewModel>

}

private struct PartialPreviewHelper: View {

  init(oldContent: String, newContent: String) {
    self.oldContent = oldContent
    self.newContent = newContent

    diff = .init(task: {
      try! await FileDiff.getColoredDiff(
        oldContent: oldContent,
        newContent: newContent,
        highlightColors: .dark(.xcode)).mockSuggestion
    })
  }

  let oldContent: String
  let newContent: String

  var body: some View {
    if let diff = diff.value {
      PartialDiffView(change: diff, partialRange: 0..<5)
    }
  }

  @Bindable private var diff: Eventual<FileDiffViewModel>

}

private let previousMediumFileContent = """
  struct CodePreview: View {
    let filePath: URL
    let fileContent: String
    let startLine: Int?
    let endLine: Int?

    var body: some View {
      Text(content)
    }
  }
  """
private let newMediumFileContent = """
  struct CodePreview: View {
    let filePath: URL
    // The content of the file 
    let text: String
    let startLine: Int?
    let endLine: Int?

    var body: some View {
      Text(text)
    }
  }
  """

private let previousLargeFileContent = """
    // 1
    // 2
    // 3
    // 4
    // 5
    // 6
    // 7
    // 8
    // 9
    // 10
  struct CodePreview: View {
    let filePath: URL
    let fileContent: String
    let startLine: Int?
    let endLine: Int?
    // 1
    // 2
    // 3
    // 4
    // 5
    // 6
    // 7
    // 8
    // 9
    // 10
    var body: some View {
      Text(content)
    }
  }
  """
private let newLargeFileContent = """
    // 1
    // 2
    // 3
    // 4
    // 5
    // 6
    // 7
    // 8
    // 9
    // 10
  struct CodePreview: View {
    let filePath: URL
    // The content of the file 
    let text: String
    let startLine: Int?
    let endLine: Int?
    // 1
    // 2
    // 3
    // 4
    // 5
    // 6
    // 7
    // 8
    // 9
    // 10
    var body: some View {
      Text(text)
    }
  }
  """

// MARK: - DebugView
#Preview {
  VStack {
    PreviewHelper(oldContent: previousMediumFileContent, newContent: newMediumFileContent)
      .border(.yellow)

    Divider()

    PreviewHelper(oldContent: previousLargeFileContent, newContent: newLargeFileContent)
      .border(.blue)

    Divider()

    PartialPreviewHelper(oldContent: previousMediumFileContent, newContent: newMediumFileContent)
      .border(.green)

  }.frame(width: 400, height: 500)
}
#endif
