// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import ServerServiceInterface
import SwiftUI
import ToolFoundation

// MARK: - LSTool.Use + DisplayableToolUse

extension LSTool.Use: DisplayableToolUse {
  public var body: AnyView {
    AnyView(ToolUseView(toolUse: ToolUseViewModel(
      status: status, directoryPath: directoryPath)))
  }
}

// MARK: - ToolUseView

struct ToolUseView: View {

  @Bindable var toolUse: ToolUseViewModel

  var body: some View {
    switch toolUse.status {
    case .running:
      runningView
    case .completed(.success(let files)):
      successView(files: files)
    case .completed(.failure(let error)):
      errorView(error: error)
    default:
      VStack { }
    }
  }

  @State private var isExpanded = false
  @State private var isHovered = false

  @Environment(\.colorScheme) private var colorScheme

  @ViewBuilder
  private var runningView: some View {
    HStack {
      Icon(systemName: "folder")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Listing \(toolUse.directoryPath.lastPathComponent)...")
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

  @ViewBuilder
  private func successView(files: LSTool.Use.Output) -> some View {
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
          Icon(systemName: "folder")
            .frame(width: 14, height: 14)
            .foregroundColor(foregroundColor)
            .frame(width: 15)
        }
        Text("Listed \(files.files.count) files in \(toolUse.directoryPath.lastPathComponent)")
          .foregroundColor(foregroundColor)
      }
      .tappableTransparentBackground()
      .onTapGesture { isExpanded.toggle() }
      .acceptClickThrough()
      if isExpanded {
        HStack {
          Spacer().frame(width: 15)
          VStack {
            ForEach(files.files) { file in
              HStack(spacing: 3) {
                if file.attr.hasPrefix("d") {
                  Icon(systemName: "folder")
                    .foregroundColor(foregroundColor)
                    .frame(width: 12, height: 12)
                } else {
                  FileIcon(filePath: URL(fileURLWithPath: file.path))
                    .frame(width: 12, height: 12)
                }
                Text(URL(fileURLWithPath: file.path).lastPathComponent)
                  .foregroundColor(foregroundColor)
                if !file.attr.starts(with: "d") {
                  Spacer()
                  Text(file.size)
                    .foregroundColor(foregroundColor)
                }
              }
              .padding(.vertical, 2)
            }
          }
        }
      }
    }.onHover { isHovered = $0 }
  }

  @ViewBuilder
  private func errorView(error: Error) -> some View {
    HStack {
      Icon(systemName: "folder")
        .frame(width: 14, height: 14)
        .foregroundColor(foregroundColor)
      Text("Listing \(toolUse.directoryPath.lastPathComponent) failed: \(error.localizedDescription)")
        .foregroundColor(foregroundColor)
    }
  }

}

// MARK: - LSTool.Use.Output.File + Identifiable

extension LSTool.Use.Output.File: Identifiable {
  public var id: String { path }
}
