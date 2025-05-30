// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import AppKit
import ChatFoundation
import Combine
import ConcurrencyFoundation
import Dependencies
import FileSuggestionServiceInterface
import Foundation
import FoundationInterfaces
import LLMFoundation
import LoggingServiceInterface
import PDFKit
import SettingsServiceInterface
import SwiftUI
import UniformTypeIdentifiers
import XcodeObserverServiceInterface

// MARK: - ChatInputViewModel

@Observable @MainActor
final class ChatInputViewModel {

  #if DEBUG
  convenience init(
    selectedModel: LLMModel? = nil,
    activeModels: [LLMModel]? = nil,
    mode: ChatMode = .agent,
    attachments: [Attachment] = [])
  {
    self.init(
      textInput: TextInput(),
      selectedModel: selectedModel,
      activeModels: activeModels,
      mode: mode,
      attachments: attachments)
  }
  #endif

  convenience init() {
    @Dependency(\.userDefaults) var userDefaults
    let selectedModel: LLMModel? =
      if let modelName = userDefaults.string(forKey: Self.userDefaultsSelectLLMModelKey) {
        LLMModel(rawValue: modelName)
      } else {
        nil
      }

    let chatMode: ChatMode =
      if let chatModeName = userDefaults.string(forKey: Self.userDefaultsChatModeKey) {
        ChatMode(rawValue: chatModeName) ?? .agent
      } else {
        .agent
      }

    self.init(
      textInput: TextInput(),
      selectedModel: selectedModel,
      activeModels: nil, // Pass nil here to signal that the value from settings should be observed.
      mode: chatMode,
      attachments: [])
  }

  /// - Parameters:
  ///   - activeModels: The available LLM models. When nil, this value is resolved from the settings and changes to the settings will be observed.
  private init(
    textInput: TextInput,
    selectedModel: LLMModel? = nil,
    activeModels: [LLMModel]?,
    mode: ChatMode = .agent,
    attachments: [Attachment])
  {
    self.textInput = textInput
    self.selectedModel = selectedModel ?? activeModels?.first
    self.mode = mode
    self.attachments = attachments

    if let activeModels {
      self.activeModels = activeModels
      updateSelectedModel()
    } else {
      @Dependency(\.settingsService) var settingsService
      let settings = settingsService.liveValues()
      self.activeModels = settings.currentValue.activeModels
      updateSelectedModel()
      settingsService.liveValues().sink { [weak self] settings in
        guard let self else { return }
        self.activeModels = settings.activeModels
        updateSelectedModel()
      }.store(in: &cancellables)
    }

    searchTasks.sink { @Sendable suggestions in
      Task { @MainActor [weak self] in
        self?.searchResults = suggestions
      }
    }.store(in: &cancellables)
  }

  /// The list of available LLM models that can be selected.
  private(set) var activeModels: [LLMModel]
  /// Attachments selected by the user as explicit context for the next message.
  var attachments: [Attachment]
  /// Whether the text input needs to be focused on. This will be reset to false once focus has been updated.
  var textInputNeedsFocus = false

  /// When searching for references, the index of the selected search result (at this point the selection has not yet been confirmed).
  var selectedSearchResultIndex = 0

  /// Which LLM model is selected to respond to the next message.
  var selectedModel: LLMModel? {
    didSet {
      if let selectedModel {
        userDefaults.set(selectedModel.id, forKey: Self.userDefaultsSelectLLMModelKey)
      }
    }
  }

  /// The chat mode to use for this conversation.
  var mode: ChatMode {
    didSet {
      userDefaults.set(mode.rawValue, forKey: Self.userDefaultsChatModeKey)
    }
  }

  /// The input text, which can contain inline references to attachments.
  var textInput: TextInput {
    didSet {
      handleTextInputChange(from: oldValue)
    }
  }

  /// The results from the current reference search.
  private(set) var searchResults: [FileSuggestion]? = nil {
    didSet {
      if let searchResults {
        selectedSearchResultIndex = max(0, min(searchResults.count - 1, selectedSearchResultIndex))
      } else {
        selectedSearchResultIndex = 0
      }
    }
  }

  /// The search query, and related information, used to find references.
  var inlineSearch: (String, NSRange, CGRect?)? {
    didSet {
      if inlineSearch?.0 != oldValue?.0 {
        updateSearchResults(searchQuery: inlineSearch?.0)
      }
    }
  }

  var externalSearchQuery: String? {
    didSet {
      if externalSearchQuery != oldValue {
        updateSearchResults(searchQuery: externalSearchQuery)
      }
    }
  }

  /// Create a deep copy of the view model.
  func copy() -> ChatInputViewModel {
    .init(
      textInput: TextInput(textInput.string),
      selectedModel: selectedModel,
      // Pass nil here to signal that the value from settings should be observed.
      // This method is not expected to be called in Previews where the mock settings might not have the right content.
      activeModels: nil,
      mode: mode,
      attachments: attachments)
  }

  func handleStartExternalSearch(isSearching: Bool) {
    if isSearching {
      externalSearchQuery = ""
    } else {
      externalSearchQuery = nil
    }
  }

  func handleCloseSearch() {
    clearSearchResults()
  }

  /// Add an attachment to the input.
  @MainActor
  func add(attachment: Attachment) {
    guard attachments.contains(where: { $0 === attachment }) == false else { return }
    attachments.append(attachment)
  }

  @MainActor
  func handleOnKeyDown(key: KeyEquivalent, modifiers: NSEvent.ModifierFlags) -> Bool {
    guard let searchResults else {
      return false
    }
    if key == .upArrow {
      selectedSearchResultIndex = max(0, selectedSearchResultIndex - 1)
      return true
    } else if key == .downArrow {
      selectedSearchResultIndex = min(searchResults.count - 1, selectedSearchResultIndex + 1)
      return true
    } else if key == .return, !modifiers.contains(.shift) {
      guard searchResults.count > selectedSearchResultIndex else {
        // Not searching, don't handle the key event.
        return false
      }
      // Handle search selection
      handleDidSelect(searchResult: searchResults[selectedSearchResultIndex])
      return true
    }
    return false
  }

  func handleDrop(of item: MultiTypeTransferable) -> Bool {
    switch item {
    case .text(let text):
      textInput.append(text)

    case .image(let image):
      guard let imageData = image.pngData else {
        assertionFailure("Could not convert image to PNG data")
        return false
      }
      let attachment = Attachment.image(.init(imageData: imageData, path: nil))
      attachments.append(attachment)

    case .file(let url):
      if let attachment = createFileAttachment(from: url) {
        attachments.append(attachment)
      }
    }
    return true
  }

  func handleDidSelect(searchResult: FileSuggestion?) {
    defer {
      clearSearchResults()
    }

    guard let searchResult else { return }

    let attachment: Attachment
    if
      let existingAttachment = attachments.first(where: { attachment in
        if case .file(let fileAttachment) = attachment {
          return fileAttachment.path == searchResult.path
        }
        return false
      })
    {
      attachment = existingAttachment
    } else {
      guard let fileAttachment = createFileAttachment(from: searchResult.path) else {
        return
      }
      attachment = fileAttachment
    }
    guard let inlineSearch else {
      // this is an external search.
      if !attachments.contains(where: { $0 === attachment }) {
        attachments.append(attachment)
      }
      return
    }

    inlineReferences[attachment.id.uuidString] = attachment
    let str = NSMutableAttributedString(attributedString: textInput.string)
    let reference = TextInput.Reference(display: "@\(searchResult.path.lastPathComponent)", id: attachment.id.uuidString)

    str.replaceCharacters(in: inlineSearch.1, with: reference.asReferenceBlock)
    str.append(NSAttributedString(string: " "))

    // We do not update `attachments` in this function as this is triggered by updating `textInput`.
    textInput = TextInput(str)
  }

  private static let userDefaultsSelectLLMModelKey = "selectedLLMModel"
  private static let userDefaultsChatModeKey = "chatMode"

  /// References to attachments within the text input.
  @ObservationIgnored private var inlineReferences = [String: Attachment]()

  @ObservationIgnored
  @Dependency(\.fileSuggestionService) private var fileSuggestionService

  @ObservationIgnored
  @Dependency(\.xcodeObserver) private var xcodeObserver

  @ObservationIgnored
  @Dependency(\.userDefaults) private var userDefaults

  @ObservationIgnored
  @Dependency(\.fileManager) private var fileManager

  private let searchTasks = ReplaceableTaskQueue<[FileSuggestion]?>()
  private var cancellables = Set<AnyCancellable>()

  private func clearSearchResults() {
    updateSearchResults(searchQuery: nil)
    inlineSearch = nil
    externalSearchQuery = nil
  }

  private func createFileAttachment(from url: URL) -> Attachment? {
    if UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true {
      guard let data = try? fileManager.read(dataFrom: url) else {
        assertionFailure("Could not read image data from \(url)")
        return nil
      }
      return Attachment.image(.init(imageData: data, path: url))
    }
    guard let content = try? fileManager.read(contentsOf: url) else {
      assertionFailure("Could not read file at \(url)")
      return nil
    }
    return Attachment.file(.init(path: url, content: content))
  }

  /// When the text input changes, detect which inline references have changed, and update the attachments accordingly.
  private func handleTextInputChange(from oldValue: TextInput) {
    let oldAttachments = oldValue.elements.compactMap(\.reference).compactMap { inlineReferences[$0.id] }
    let newAttachments = textInput.elements.compactMap(\.reference).compactMap { inlineReferences[$0.id] }

    let addedAttachments = newAttachments.filter { !oldAttachments.contains($0) }
    let removedAttachments = oldAttachments.filter { !newAttachments.contains($0) }

    for addedAttachment in addedAttachments { attachments.append(addedAttachment) }
    for attachment in removedAttachments {
      attachments.removeAll(where: { $0.id == attachment.id })
    }
  }

  /// When the search query has changed, update the search results accordingly.
  private func updateSearchResults(searchQuery: String?) {
    guard let searchQuery, let workspaceUrl = xcodeObserver.state.focusedWorkspace?.url else {
      searchResults = nil
      selectedSearchResultIndex = 0
      textInputNeedsFocus = true
      // Queue a nil value to clear the pending search results.
      searchTasks.queue { nil }

      return
    }
    let fileSuggestionService = fileSuggestionService
    searchTasks.queue {
      try await fileSuggestionService.suggestFiles(for: searchQuery, in: workspaceUrl, top: 50)
    }
  }

  private func updateSelectedModel() {
    if let selectedModel, activeModels.contains(selectedModel) {
      return
    }
    selectedModel = activeModels.first
  }

}

// MARK: - TextInput

struct TextInput {

  init(_ elements: [Element] = []) {
    self.elements = elements
  }

  enum Element {
    case text(_ text: String)
    case reference(_ reference: Reference)

    var reference: Reference? {
      if case .reference(let reference) = self {
        return reference
      }
      return nil
    }

    var text: String? {
      if case .text(let text) = self {
        return text
      }
      return nil
    }
  }

  struct Reference: Equatable {
    let display: String
    let id: String
  }

  var elements: [Element]

  var isEmpty: Bool {
    elements.isEmpty
  }

  mutating func append(_ str: String) {
    if case .text(let lastText) = elements.last {
      elements[elements.count - 1] = .text(lastText + str)
    } else {
      elements.append(.text(str))
    }
  }
}

extension NSImage {
  var pngData: Data? {
    guard let tiffData = tiffRepresentation else { return nil }
    let bitmap = NSBitmapImageRep(data: tiffData)
    return bitmap?.representation(using: .png, properties: [:])
  }
}
