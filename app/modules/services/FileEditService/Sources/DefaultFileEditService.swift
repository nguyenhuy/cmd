// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import DependencyFoundation
import FileEditServiceInterface
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import XcodeControllerServiceInterface

// MARK: - DefaultFileEditService

final class DefaultFileEditService: FileEditService {

  init(
    fileManager: FileManagerI,
    xcodeController: XcodeController)
  {
    self.fileManager = fileManager
    self.xcodeController = xcodeController
  }

  func trackChangesOfFile(at path: URL) throws -> FileReference {
    let cancellable = try fileManager.observeChangesToContent(of: path) { newContent in
      self.process(newContent: newContent, for: path)
    }

    let content = try fileManager.read(contentsOf: path)

    let fileState = FileState(history: [content], path: path)
    state.mutate {
      $0.cancellables.insert(cancellable)
      $0.trackedFiles[path.path] = fileState
    }

    return DefaultFileReference(path: path, fileManager: fileManager)
  }

  func apply(change: FileChange) async throws {
    // Update the file history when the change is applied, as applying the change to the editor will not change the file content on disk
    // and the history would be out of date.
    let updateFileHistory = {
      let newContent = change.suggestedNewContent
      let subscribers: [FileChangeSubscriber]? = self.state.mutate {
        if var fileState = $0.trackedFiles[change.filePath.path()] {
          if newContent != fileState.history.last {
            fileState.history.append(newContent)
            return fileState.subscribers
          }
        }
        return nil
      }
      subscribers?.forEach { $0(newContent) }
    }
    defer { updateFileHistory() }

    try await xcodeController.apply(fileChange: change)
  }

  func subscribeToContentChange(to fileReference: FileReference, onChange: @escaping FileChangeSubscriber) {
    state.mutate {
      $0.trackedFiles[fileReference.path.path()]?.subscribers.append(onChange)
    }
  }

  private struct InternalState: Sendable {
    var trackedFiles: [String: FileState] = [:]
    var cancellables: Set<AnyCancellable> = []
  }

  private let fileManager: FileManagerI

  private let xcodeController: XcodeController

  private let state = Atomic<InternalState>(.init())

  private func process(newContent: String?, for path: URL) {
    guard let newContent else {
      // File deleted, not handled
      return
    }

    let subscribers = state.mutate {
      $0.trackedFiles[path.path()]?.history.append(newContent)
      return $0.trackedFiles[path.path()]?.subscribers
    }
    subscribers?.forEach { $0(newContent) }
  }

}

// MARK: - DefaultFileReference

struct DefaultFileReference: FileReference {
  init(path: URL, fileManager: FileManagerI) {
    self.path = path
    self.fileManager = fileManager
  }

  let path: URL
  private let fileManager: FileManagerI

  var currentContent: String {
    get throws { try fileManager.read(contentsOf: path) }
  }
}

// MARK: - FileState

struct FileState: Sendable {
  var history: [String] = []
  var path: URL
  var subscribers: [FileChangeSubscriber] = []
}

extension BaseProviding where
  Self: XcodeControllerProviding,
  Self: FileManagerProviding
{
  public var fileEditService: FileEditService {
    shared {
      DefaultFileEditService(
        fileManager: fileManager,
        xcodeController: xcodeController)
    }
  }
}
