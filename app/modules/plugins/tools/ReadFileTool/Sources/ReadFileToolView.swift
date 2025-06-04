// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CodePreview
import DLS
import ServerServiceInterface
import SwiftUI
import ToolFoundation

// MARK: - ReadFileTool.Use + DisplayableToolUse

extension ReadFileTool.Use: DisplayableToolUse {
  public var body: AnyView {
    AnyView(ToolUseView(toolUse: ToolUseViewModel(
      status: status, input: input)))
  }
}

// MARK: - ToolUseView

struct ToolUseView: View {

  @Bindable var toolUse: ToolUseViewModel

  var body: some View {
    switch toolUse.status {
    case .notStarted:
      VStack { }
    case .pendingApproval:
      pendingApprovalView
    case .rejected:
      rejectedView
    case .running:
      runningView
    case .completed(.success(let output)):
      successView(output: output)
    case .completed(.failure(let error)):
      errorView(error: error)
    }
  }

  @State private var isExpanded = false
  @State private var isHovered = false

  @Environment(\.colorScheme) private var colorScheme

  @ViewBuilder
  private var pendingApprovalView: some View {
    HStack {
      Icon(systemName: "doc.text")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Waiting for approval: Read \(toolUse.filePath.lastPathComponent)\(rangeDisplay)")
        .foregroundColor(foregroundColor)
    }
  }

  @ViewBuilder
  private var rejectedView: some View {
    HStack {
      Icon(systemName: "doc.text")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Rejected: Read \(toolUse.filePath.lastPathComponent)\(rangeDisplay)")
        .foregroundColor(foregroundColor)
    }
  }

  @ViewBuilder
  private var runningView: some View {
    HStack {
      Icon(systemName: "doc.text")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Reading \(toolUse.filePath.lastPathComponent)\(rangeDisplay)...")
        .foregroundColor(foregroundColor)
    }
  }

  private var foregroundColor: Color {
    if isHovered {
      .primary
    } else {
      colorScheme.toolUseForeground
    }
  }

  private var rangeDisplay: String {
    if let range = toolUse.input.lineRange {
      " L\(range.start)-\(range.end)"
    } else {
      ""
    }
  }

  @ViewBuilder
  private func successView(output: ReadFileTool.Use.Output) -> some View {
    VStack(alignment: .leading) {
      HStack {
        if isExpanded {
          Icon(systemName: "chevron.down")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        } else if isHovered {
          Icon(systemName: "chevron.right")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        } else {
          Icon(systemName: "doc.text")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        }

        Text("Read \(toolUse.filePath.lastPathComponent)\(rangeDisplay)")
          .foregroundColor(foregroundColor)
      }
      .tappableTransparentBackground()
      .onTapGesture { isExpanded.toggle() }
      .acceptClickThrough()
      if isExpanded {
        CodePreview(
          filePath: URL(fileURLWithPath: output.uri),
          language: FileIcon.language(for: URL(fileURLWithPath: output.uri)),
          content: output.content,
          highlightedContent: toolUse.highlightedContent,
          collapsedHeight: 400)
      }
    }.onHover { isHovered = $0 }
  }

  @ViewBuilder
  private func errorView(error: Error) -> some View {
    HStack {
      Icon(systemName: "doc.text")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Reading \(toolUse.filePath.lastPathComponent)\(rangeDisplay) failed: \(error.localizedDescription)")
        .foregroundColor(foregroundColor)
    }
  }

}

// MARK: - ReadFileTool.Use.Output + Identifiable

extension ReadFileTool.Use.Output: Identifiable {
  public var id: String { uri }
}

extension ToolUseViewModel {
  var filePath: URL { URL(fileURLWithPath: input.path) }
}
