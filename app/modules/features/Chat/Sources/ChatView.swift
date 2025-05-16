// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import ConcurrencyFoundation
import DLS
import SwiftUI

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
    SettingsView: @escaping @MainActor () -> AnyView = { AnyView(EmptyView()) })
  {
    self.viewModel = viewModel
    self.SettingsView = SettingsView
  }

  public var body: some View {
    NavigationStack(path: $path) {
      VStack(spacing: 0) {
        quickActionsRow
        if let selectedTab = viewModel.selectedTab {
          ChatMessageList(events: selectedTab.events, onRestoreTapped: { [weak selectedTab] checkpoint in
            selectedTab?.handleRestore(checkpoint: checkpoint)
          })
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
      .navigationDestination(for: SettingsLink.self) { _ in
        VStack(spacing: 0) {
          SettingsView()
        }
      }
    }
  }

  @State private var path = NavigationPath()

  @Environment(\.colorScheme) private var colorScheme

  private let SettingsView: () -> AnyView

  @Bindable private var viewModel: ChatViewModel

  private let iconSizes: CGFloat = 22

  @ViewBuilder
  private var quickActionsRow: some View {
    HStack(spacing: 0) {
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
          path.append(SettingsLink())
        },
        systemName: "gearshape",
        onHoverColor: colorScheme.secondarySystemBackground,
        padding: 4)
        .frame(width: iconSizes, height: iconSizes)
        .padding(4)
    }
  }

}

// MARK: - SettingsLink

struct SettingsLink: Hashable { }
