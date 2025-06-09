// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Combine
import ConcurrencyFoundation
import Dependencies
import DLS
import FoundationInterfaces
import SwiftUI
import XcodeObserverServiceInterface

// MARK: - ChatView

/// A view that provides a chat interface with multiple tabs support.
///
/// `ChatView` implements a tabbed chat interface where each tab represents a separate chat conversation.
/// The view consists of three main components:
/// - A tab bar for managing multiple chat sessions
/// - A message list displaying the conversation
/// - An input view for sending new messages
///
/// Example usage:
/// ```swift
/// let viewModel = ChatViewModel(tabs: [])
/// ChatView(viewModel: viewModel)
/// ```
///
/// - Note: The view supports drag and drop functionality for images and files.
public struct ChatView: View {

  public init(
    viewModel: ChatViewModel,
    SettingsView: @escaping @MainActor (@escaping @MainActor () -> Void) -> AnyView = { _ in AnyView(EmptyView()) })
  {
    self.viewModel = viewModel
    self.SettingsView = SettingsView
  }

  public var body: some View {
    ZStack(alignment: .top) {
      VStack(spacing: 0) {
        quickActionsRow
        secondaryActionRow
        if let selectedTab = viewModel.selectedTab {
          ChatMessageList(viewModel: selectedTab)
            .id("ChatMessageList-\(selectedTab.id)")
          ChatInputView(
            inputViewModel: selectedTab.input,
            isStreamingResponse: Bindable(selectedTab).isStreamingResponse,
            didTapCancel: { [weak selectedTab] in
              selectedTab?.cancelCurrentMessage()
            },
            didSend: { [weak selectedTab] in
              Task {
                await selectedTab?.sendMessage()
              }
            }).id("ChatInputView-\(selectedTab.id)")
        }
      }
      if showSettingsSheet {
        SettingsView {
          showSettingsSheet = false
        }
      }
    }
    .background(colorScheme.primaryBackground)
  }

  var projectName: String? {
    viewModel.selectedTab?.projectInfo?.path.lastPathComponent.split(separator: ".").first.map(String.init)
  }

  var focusedWorkspaceName: String? {
    viewModel.focusedWorkspacePath?.lastPathComponent.split(separator: ".").first.map(String.init)
  }

  @State private var showSettingsSheet = false

  @Environment(\.colorScheme) private var colorScheme

  @Dependency(\.userDefaults) private var userDefaults
  private let SettingsView: (@escaping @MainActor () -> Void) -> AnyView

  @Bindable private var viewModel: ChatViewModel

  private let iconSizes: CGFloat = 22

  @ViewBuilder
  private var quickActionsRow: some View {
    HStack(spacing: 0) {
      projectHeader
      Spacer(minLength: 0)
      IconButton(
        action: {
          viewModel.addTab()
        },
        systemName: "plus",
        onHoverColor: colorScheme.secondarySystemBackground,
        padding: 4)
        .frame(width: iconSizes, height: iconSizes)
        .padding(4)

      IconButton(
        action: {
          showSettingsSheet = true
        },
        systemName: "gearshape",
        onHoverColor: colorScheme.secondarySystemBackground,
        padding: 4)
        .frame(width: iconSizes, height: iconSizes)
        .padding(4)
    }
  }

  @ViewBuilder
  private var projectHeader: some View {
    if let projectName {
      HStack(spacing: 8) {
        Image("xcodeproj-icon")
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)

        Text(projectName)
          .foregroundColor(.primary)
          .lineLimit(1)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .cornerRadius(6)
    }
  }

  @ViewBuilder
  private var secondaryActionRow: some View {
    if viewModel.focusedWorkspacePath != nil, viewModel.selectedTab?.projectInfo?.path != viewModel.focusedWorkspacePath {
      HStack {
        focusOnNewProjectCTA
        Spacer()
      }
    }
  }

  /// Display a helpful message when the project focussed in Xcode is not the one focussed on in the chat,
  /// to avoid the user wondering how to add info from the current workspace.
  @ViewBuilder
  private var focusOnNewProjectCTA: some View {
    if let workspaceName = focusedWorkspaceName {
      HoveredButton(
        action: {
          viewModel.addTab()
        },
        onHoverColor: colorScheme.secondarySystemBackground)
      {
        HStack(spacing: 6) {
          Image(systemName: "plus.circle.fill")
            .font(.caption2)
          Text("Focus on \(workspaceName) in a new thread")
            .font(.caption2)
            .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(4)
      }
      .buttonStyle(PlainButtonStyle())
      .padding(.top, 2)
      .padding(.horizontal, 8)
    }
  }

}

// MARK: - SettingsLink

struct SettingsLink: Hashable { }
