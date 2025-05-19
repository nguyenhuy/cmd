// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CodePreview
import Combine
import FileDiffFoundation
import Foundation
import Observation
import ToolFoundation

// MARK: - ToolUseViewModel

@Observable
@MainActor
final class ToolUseViewModel {

  init(
    status: EditFilesTool.Use.Status,
    input: EditFilesTool.Use.Input,
    isInputComplete: Bool)
  {
    self.status = status.value
    self.input = input
    self.isInputComplete = isInputComplete

    handleUpdatedInput()

    Task { [weak self] in
      for await status in status {
        self?.status = status
      }
    }
  }

  var isInputComplete: Bool
  var status: ToolUseExecutionStatus<EditFilesTool.Output>

  var input: EditFilesTool.Use.Input {
    didSet {
      handleUpdatedInput()
    }
  }

  var changes: [(path: URL, change: FileDiffViewModel)] {
    changedFiles.compactMap { file in
      guard let model = changedFilesModels[file.path] else { return nil }
      return (file, model)
    }
  }

  private var changedFiles = [URL]()
  private var changedFilesModels = [String: FileDiffViewModel]()

  private func handleUpdatedInput() {
    // Ensure changes to each given file are grouped together, in case the LLM would not do this well.
    var changes = [String: [EditFilesTool.Use.Input.FileChange.Change]]()
    var changedFiles = [URL]()
    for file in input.files {
      if var existingChanges = changes[file.path] {
        existingChanges.append(contentsOf: file.changes)
        changes[file.path] = existingChanges
      } else {
        changes[file.path] = file.changes
        changedFiles.append(URL(fileURLWithPath: file.path))
      }
    }
    self.changedFiles = changedFiles

    // For each file,
    for (filePath, changes) in changes {
      updateChanges(for: URL(filePath: filePath), changes: changes)
    }
  }

  private func updateChanges(for file: URL, changes: [EditFilesTool.Use.Input.FileChange.Change]) {
    if let model = changedFilesModels[file.path] {
      model.handle(newChanges: changes.map { .init(search: $0.search, replace: $0.replace) })
    } else {
      if
        let model = FileDiffViewModel(filePath: file.path, changes: changes.map {
          FileDiff.SearchReplace(search: $0.search, replace: $0.replace)
        })
      {
        changedFilesModels[file.path] = model
      }
    }
  }

}
