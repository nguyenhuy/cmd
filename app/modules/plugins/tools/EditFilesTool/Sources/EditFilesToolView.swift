// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CodePreview
import DLS
import FileDiffFoundation
import FileDiffTypesFoundation
import ServerServiceInterface
import SwiftUI
import ToolFoundation

// MARK: - EditFilesTool.Use + DisplayableToolUse

extension EditFilesTool.Use: DisplayableToolUse {
  public var body: AnyView {
    AnyView(ToolUseView(toolUse: viewModel))
  }
}

// MARK: - ToolUseView

struct ToolUseView: View {

  @Bindable var toolUse: ToolUseViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        ForEach(toolUse.changes, id: \.path) { fileChange in
          FileChangeView(change: fileChange.change)
        }
      }
      .padding(.vertical)
    }
  }

  @Environment(\.colorScheme) private var colorScheme
}

// MARK: - FileDiffViewModel Extensions

extension FileDiffViewModel {
  var filename: String {
    filePath.lastPathComponent
  }

  var additionCount: Int? {
    formattedDiff?.changes.filter { $0.change.type == .added }.count
  }

  var deletionCount: Int? {
    formattedDiff?.changes.filter { $0.change.type == .removed }.count
  }
}

// MARK: - FileChangeView

struct FileChangeView: View {
  let change: FileDiffViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      // Tab-style header when collapsed
      Button(action: {
        isExpanded.toggle()
      }) {
        HStack(spacing: 8) {
          FileIcon(filePath: change.filePath)
            .frame(width: 16, height: 16)

          Button(action: {
            openFile()
          }) {
            Text(change.filename)
              .font(.system(size: 12))
              .foregroundColor(colorScheme.primaryForeground)
          }
          .buttonStyle(PlainButtonStyle())
          .help("Open file")
          if let additionCount = change.additionCount, let deletionCount = change.deletionCount {
            // Addition/deletion counts
            HStack(spacing: 2) {
              Text("+\(additionCount)")
                .font(.system(size: 10))
                .foregroundColor(colorScheme.addedLineDiffText)

              Text("-\(deletionCount)")
                .font(.system(size: 10))
                .foregroundColor(colorScheme.removedLineDiffText)
            }
          }

          Spacer()

          // Action buttons (visible on hover)
          if isHovering {
            HStack(spacing: 12) {
              // Copy button
              IconButton(
                action: { copyChanges() },
                systemName: "doc.on.doc",
                cornerRadius: 0,
                withCheckMark: true)
                .frame(width: 10, height: 10)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .help("Copy changes")

              // Apply/Checkmark button
              Button(action: { applyChanges() }) {
                Image(systemName: "checkmark")
                  .foregroundColor(.secondary)
                  .font(.system(size: 10))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Apply changes")

              // Reject/X button
              Button(action: { rejectChanges() }) {
                Image(systemName: "xmark")
                  .foregroundColor(.secondary)
                  .font(.system(size: 10))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Reject changes")
            }
          }

          // Expand/collapse button (hidden but keeps the tap area)
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.secondary)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isHovering ? colorScheme.secondarySystemBackground : colorScheme.tertiarySystemBackground)
        .cornerRadius(isExpanded ? 0 : Constants.cornerRadius)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
          isHovering = hovering
        }
      }
      .buttonStyle(PlainButtonStyle())

      // Main content - only shown when expanded
      if isExpanded {
        CodePreview(
          fileChange: change,
          collapsedHeight: 250,
          expandedHeight: nil)
      }
    }
    .roundedCorner(radius: Constants.cornerRadius, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
    .overlay(
      RoundedCornerShape(radius: Constants.cornerRadius, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
        .stroke(colorScheme.textAreaBorderColor, lineWidth: 1))
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
  }

  private enum Constants {
    static let cornerRadius: CGFloat = 5
  }

  @State private var isExpanded = false
  @State private var isHovering = false

  @Environment(\.colorScheme) private var colorScheme

  private func copyChanges() {
    // Implement copy functionality
    print("Copy changes for \(change.filename)")
  }

  private func applyChanges() {
    // Implement apply functionality
    print("Apply changes for \(change.filename)")
  }

  private func rejectChanges() {
    // Implement reject functionality
    print("Reject changes for \(change.filename)")
  }

  private func openFile() {
    // Implement file opening functionality
    print("Open file: \(change.filePath)")
  }
}

#if DEBUG
/// Add initiallyExpanded parameter to FileChangeView for preview purposes
extension FileChangeView {
  init(change: FileDiffViewModel, initiallyExpanded: Bool = false) {
    self.change = change
    _isExpanded = State(initialValue: initiallyExpanded)
  }
}
#endif
