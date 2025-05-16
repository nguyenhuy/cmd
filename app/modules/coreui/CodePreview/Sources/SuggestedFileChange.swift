// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Combine
import ConcurrencyFoundation
import Dependencies
import FileDiffFoundation
import FileDiffTypesFoundation
import FileEditServiceInterface
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import Observation
import XcodeObserverServiceInterface

// MARK: - SuggestedFileChange

/// Represents a change that was suggested, and the relevant information about the changed file history.
@Observable @MainActor
public final class SuggestedFileChange: @unchecked Sendable {

  public convenience init?(
    filePath: String,
    llmDiff: String)
  async {
    // Variables used to log debug info if something fails.
    var _oldContent: String?
    var _newContent: String?
    do {
      let path = URL(fileURLWithPath: filePath)
      @Dependency(\.fileEditService) var fileEditService
      let fileReference = try fileEditService.trackChangesOfFile(at: path)
      guard let oldContent = try? fileReference.currentContent else {
        throw AppError(message: "File content not available for \(path)")
      }
      _oldContent = oldContent

      let newContent = try FileDiff.apply(searchReplacePattern: llmDiff, to: oldContent)
      _newContent = newContent

      if newContent == oldContent {
        return nil
      }

      let gitDiff = try FileDiff.getGitDiff(oldContent: oldContent, newContent: newContent)

      let formattedDiff = try await FileDiff.getColoredDiff(
        oldContent: oldContent,
        newContent: newContent,
        gitDiff: gitDiff,
        highlightColors: .dark(.xcode))

      self.init(
        filePath: path,
        baseLineContent: oldContent,
        targetContent: newContent,
        llmDiff: llmDiff,
        gitDiff: gitDiff,
        canBeApplied: true,
        fileRef: fileReference,
        formattedDiff: formattedDiff)
    } catch {
      defaultLogger.error("""
        Could not format diff for \(filePath): \(error)
        -- Diff:
        \(llmDiff)
        -- Previous Content:
        \(_oldContent ?? "?")
        -- New Content:
        \(_newContent ?? "?")
        --
        """)
      return nil
    }
  }

  public init(
    filePath: URL,
    baseLineContent: String,
    targetContent: String,
    llmDiff: String,
    gitDiff: String,
    canBeApplied: Bool,
    fileRef: FileReference,
    formattedDiff: FormattedFileChange)
  {
    self.filePath = filePath
    self.baseLineContent = baseLineContent
    self.targetContent = targetContent
    self.llmDiff = llmDiff
    self.gitDiff = gitDiff
    self.canBeApplied = canBeApplied
    self.fileRef = fileRef
    self.formattedDiff = formattedDiff

    fileEditService.subscribeToContentChange(to: fileRef) { newContent in
      Task { @MainActor [weak self] in
        self?.handle(fileChangedTo: newContent)
      }
    }

    cancellable = diffingTasks.sink { @Sendable newValue in
      Task { @MainActor [weak self] in
        guard let self, let newValue else { return }
        self.canBeApplied = newValue.canBeApplied
        self.formattedDiff = newValue.formattedDiff
        self.baseLineContent = newValue.baseLineContent
      }
    }
  }

  /// The path to the file to change.
  public let filePath: URL // TODO: consider how this would work if the file was moved.
  /// A reference to the file to change. This reference can be used to get more information about the file edit history.
  public let fileRef: FileReference
  /// The suggested changes, in the format used by the LLM to represent them.
  public let llmDiff: String
  /// The content of the file when the suggestion was made.
  public private(set) var baseLineContent: String
  /// The suggested changes, in git format.
  public private(set) var gitDiff: String

  /// The content of the file if the suggestion was applied.
  public private(set) var targetContent: String
  /// Whether the suggestion can be applied at this time, given the current state of the file.
  public private(set) var canBeApplied: Bool
  /// A representation of the change in diff format with syntax highlighting.
  public private(set) var formattedDiff: FormattedFileChange

  @MainActor
  public func handleApply(changes: [FormattedLineChange]) async throws {
    let fileManager = fileManager
    let formattedDiff = formattedDiff
    let filePath = filePath
    let fileEditService = fileEditService
    let xcodeObserver = xcodeObserver

    // detach to avoid blocking the main actor, as for a long file this could take a bit.
    let task = Task.detached {
      // Try to get the content from the editor over the content from disk if possible.
      // TODO: look into doing this update _after_ the file has been made visible in Xcode.
      let editorContent = xcodeObserver.state.wrapped?.xcodesState.compactMap { xc in
        xc.workspaces.compactMap { ws in
          ws.tabs.compactMap { tab in
            tab.knownPath == filePath ? tab.lastKnownContent : nil
          }.first
        }.first
      }.first
      let currentContent = try editorContent ?? fileManager.read(contentsOf: filePath, encoding: .utf8)
      let targetContent = formattedDiff.changes.map(\.change).targetContent(applying: changes.map(\.change))

      let fileDiff = try FileDiff.getFileChange(changing: currentContent, to: targetContent)
      let fileChange = FileChange(
        filePath: filePath,
        oldContent: currentContent,
        suggestedNewContent: fileDiff.newContent,
        selectedChange: fileDiff.diff)
      try await fileEditService.apply(change: fileChange)
    }
    try await task.value
  }

  @MainActor
  public func handleReject(changes: [FormattedLineChange]) async {
    let newDiff = formattedDiff.changes.suggestedContent(rejecting: changes)
    let newTargetContent = newDiff.map(\.change).targetContent

    targetContent = newTargetContent
    formattedDiff = FormattedFileChange(changes: newDiff)
  }

  @MainActor
  public func handleApplyAllChange() async throws {
    try await handleApply(changes: formattedDiff.changes)
  }

  @MainActor
  public func handleReapplyChange() async {
    if
      let updatedSuggestion = await SuggestedFileChange(
        filePath: filePath.path(),
        llmDiff: llmDiff)
    {
      baseLineContent = updatedSuggestion.baseLineContent
      gitDiff = updatedSuggestion.gitDiff
      targetContent = updatedSuggestion.targetContent
      canBeApplied = updatedSuggestion.canBeApplied
      formattedDiff = updatedSuggestion.formattedDiff
    }
  }

  private struct SuggestionUpdate: Sendable {
    /// Whether the suggestion can be applied at this time, given the current state of the file.
    public let canBeApplied: Bool
    /// A representation of the change in diff format with syntax highlighting.
    public let formattedDiff: FormattedFileChange
    /// The current content of the file.
    public let baseLineContent: String
  }

  @ObservationIgnored
  @Dependency(\.fileManager) private var fileManager

  private var cancellable: AnyCancellable?

  @ObservationIgnored
  @Dependency(\.fileEditService) private var fileEditService
  @ObservationIgnored
  @Dependency(\.xcodeObserver) private var xcodeObserver

  private let diffingTasks = ReplaceableTaskQueue<SuggestionUpdate?>()

  private func handle(fileChangedTo newContent: String?) {
    guard let newContent else {
      defaultLogger.error("The file \(filePath.path()) content became unavailable")
      return
    }

    let baseLineContent = baseLineContent
    let targetContent = targetContent

    diffingTasks.queue {
      let rebasedTargetContent = try FileDiff.rebaseChange(
        baselineContent: baseLineContent,
        currentContent: newContent,
        targetContent: targetContent)

      let formatterDiff = try await FileDiff.getColoredDiff(
        oldContent: newContent,
        newContent: rebasedTargetContent,
        highlightColors: .dark(.xcode))

      return SuggestionUpdate(
        canBeApplied: !rebasedTargetContent.contains("<<<<<<<"),
        formattedDiff: formatterDiff,
        baseLineContent: newContent)
    }
  }

}
