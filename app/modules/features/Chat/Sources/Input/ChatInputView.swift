// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import AppKit
import ChatFoundation
import Combine
import ConcurrencyFoundation
import Dependencies
import DLS
import LLMFoundation
import LoggingServiceInterface
import SwiftUI

// MARK: - ChatInputView

@MainActor
struct ChatInputView: View {

  init(
    inputViewModel: ChatInputViewModel,
    isStreamingResponse: Binding<Bool>,
    didTapCancel: @escaping () -> Void,
    didSend: @escaping () -> Void)
  {
    self.inputViewModel = inputViewModel
    _isStreamingResponse = isStreamingResponse
    self.didTapCancel = didTapCancel
    self.didSend = didSend
    #if DEBUG
    _debugTextViewHandler = nil
    #endif
  }

  #if DEBUG
  init(
    _debugTextViewHandler: @escaping @Sendable (NSTextView) -> Void,
    inputViewModel: ChatInputViewModel,
    isStreamingResponse: Binding<Bool>,
    didTapCancel: @escaping () -> Void,
    didSend: @escaping () -> Void)
  {
    self.inputViewModel = inputViewModel
    _isStreamingResponse = isStreamingResponse
    self.didTapCancel = didTapCancel
    self.didSend = didSend
    self._debugTextViewHandler = _debugTextViewHandler
  }
  #endif

  static let cornerRadius: CGFloat = 10

  #if DEBUG
  let _debugTextViewHandler: (@Sendable (NSTextView) -> Void)?
  #endif

  var body: some View {
    VStack(spacing: 0) {
      if let pendingApproval = inputViewModel.pendingApproval {
        ToolApprovalView(
          request: pendingApproval,
          onApprove: {
            inputViewModel.handleApproval(of: pendingApproval, result: .approved)
          },
          onDeny: {
            inputViewModel.handleApproval(of: pendingApproval, result: .denied)
          },
          onAlwaysApprove: {
            inputViewModel.handleApproval(of: pendingApproval, result: .alwaysApprove(toolName: pendingApproval.toolName))
          })
          .transition(
            .asymmetric(
              insertion: .move(edge: .bottom).combined(with: .opacity),
              removal: .move(edge: .bottom).combined(with: .opacity)))
      }
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 8) {
          AttachmentsView(
            searchAttachment: inputViewModel.handleStartExternalSearch,
            attachments: $inputViewModel.attachments)
        }
        .padding(.horizontal, sidePadding)
        .padding(.vertical, sidePadding)
        textInput
        Rectangle()
          .foregroundColor(.clear)
          .frame(height: 6)
        bottomRow
      }
    }
    .overlay {
      DragDropAreaView(shape: AnyShape(RoundedRectangle(cornerRadius: Self.cornerRadius)), handleDrop: inputViewModel.handleDrop)
    }
    .background(
      RoundedRectangle(cornerRadius: Self.cornerRadius)
        .fill(colorScheme.xcodeInputBackground)
        .overlay(
          RoundedRectangle(cornerRadius: Self.cornerRadius)
            .stroke(colorScheme.textAreaBorderColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius)))
    .overlay(alignment: .top) {
      if let searchResults = inputViewModel.searchResults {
        SearchResultsView(
          selectedRowIndex: $inputViewModel.selectedSearchResultIndex,
          results: searchResults,
          didSelect: inputViewModel.handleDidSelect,
          searchInput: $inputViewModel.externalSearchQuery)
          .readingSize { size in searchResultsViewHeight = size.height }
          .offset(y: -searchResultsViewHeight)
          .onOutsideTap {
            inputViewModel.handleCloseSearch()
          }
      }
    }
    .padding(8)
    .overlay(alignment: .top) {
      if isStreamingResponse {
        stopStreamButton
          .offset(y: -30)
      }
    }
    .animation(.easeInOut, value: inputViewModel.pendingApproval != nil)
    .onTapGesture {
      inputViewModel.textInputNeedsFocus = true
    }
  }

  @State private var searchResultsViewHeight: CGFloat = 0

  @Environment(\.colorScheme) private var colorScheme

  /// Is a streaming chat response in progress
  @Binding private var isStreamingResponse: Bool

  @State private var scrollViewContentSize = CGSize.zero

  @Bindable private var inputViewModel: ChatInputViewModel

  private let sidePadding: CGFloat = 6

  private var didTapCancel: () -> Void

  private var didSend: () -> Void

  private var isInputReady: Bool {
    !inputViewModel.textInput.isEmpty
  }

  private var textInput: some View {
    VStack {
      HStack(alignment: .center, spacing: sidePadding) {
        chatInputTextEditor
      }
    }
    .padding(.top, 4)
    .padding(.horizontal, sidePadding)
  }

  private var chatModeSelection: some View {
    PopUpSelectionMenu(
      selectedItem: $inputViewModel.mode,
      availableItems: ChatMode.allCases)
    { mode in
      switch mode {
      case .agent:
        AgentModeView()
      case .ask:
        AskModeView()
      }
    }
  }

  private var bottomRow: some View {
    HStack(alignment: .center, spacing: 6) {
      chatModeSelection
      PopUpSelectionMenu(
        selectedItem: $inputViewModel.selectedModel,
        availableItems: inputViewModel.activeModels,
        emptySelectionText: "No model configured")
      { model in
        Text(model.name)
      }
      ImageAttachmentPickerView(attachments: $inputViewModel.attachments)
      HStack(spacing: 10) {
        Spacer()
        if !isStreamingResponse {
          sendButton
        }
      }
      .padding(.bottom, 4)
    }
    .padding(.bottom, 4)
    .padding(.horizontal, 8)
  }

  private var chatInputTextEditor: some View {
    VStack(alignment: .leading) {
      ScrollView([.vertical]) {
        RichTextEditor(
          text: Binding<NSAttributedString>(
            get: { inputViewModel.textInput.string },
            set: { inputViewModel.textInput = TextInput($0) }),
          needsFocus: $inputViewModel.textInputNeedsFocus,
          onFocusChanged: { isFocused in
            if inputViewModel.textInputNeedsFocus, isFocused {
              inputViewModel.textInputNeedsFocus = false
            }
          },
          onSearch: { search in
            inputViewModel.inlineSearch = search
          },
          onKeyDown: { key, modifiers in onKeyDown(key: key, modifiers: modifiers) },
          placeholder: "Write something here")
          .scrollContentBackground(.hidden)
          .fixedSize(horizontal: false, vertical: true)
          .onAppear {
            inputViewModel.textInputNeedsFocus = true
          }
          .padding(.bottom, 8)
          .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
          } action: { size in
            scrollViewContentSize = size
          }
      }
    }.defaultScrollAnchor(.bottom)
      .frame(maxHeight: scrollViewHeight)
  }

  private var scrollViewHeight: CGFloat {
    min(200, scrollViewContentSize.height)
  }

  private var sendButton: some View {
    Button(action: {
      sendIfReady()
    }) {
      HStack(spacing: 2) {
        Image(systemName: "return")
        Text("chat")
      }
      .tappableTransparentBackground()
    }
    .acceptClickThrough()
    .buttonStyle(.plain)
    .foregroundColor(isInputReady ? .primary : .secondary)
    .id("chat button")
  }

  private var stopStreamButton: some View {
    HStack {
      Button {
        didTapCancel()
      } label: {
        HStack(spacing: 2) {
          Image(systemName: "command")
          Image(systemName: "delete.left")
          Text("Stop")
        }
      }
      .acceptClickThrough()
    }
  }

  private func sendIfReady() {
    guard isInputReady else {
      return
    }
    didSend()
  }

  private func onKeyDown(key: KeyEquivalent, modifiers: NSEvent.ModifierFlags) -> Bool {
    // The input view gets to handle the key event first
    if inputViewModel.handleOnKeyDown(key: key, modifiers: modifiers) {
      return true
    }
    if key == .return, !modifiers.contains(.shift) {
      sendIfReady()
      return true
    }
    return false
  }
}

// MARK: - LLMModel + MenuItem

extension LLMModel: MenuItem { }

// MARK: - ChatMode + MenuItem

extension ChatMode: MenuItem {
  public var id: String { rawValue }
}
