// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import FileDiffTypesFoundation
import Foundation
import ThreadSafe
#if DEBUG
// MARK: - MockFileEditService

@ThreadSafe
public final class MockFileEditService: FileEditService {

  public init(
    currentContent: String? = nil,
    onTrackChangesOfFile: (@Sendable (URL) throws -> FileReference)? = nil,
    onSubscribeToContentChange: (@Sendable (FileReference, @Sendable @escaping (String?) -> Void) -> Void)? = nil,
    onApply: (@Sendable (FileChange) async throws -> Void)? = nil)
  {
    self.currentContent = currentContent
    self.onTrackChangesOfFile = onTrackChangesOfFile
    self.onSubscribeToContentChange = onSubscribeToContentChange
    self.onApply = onApply
  }

  public var currentContent: String?
  public var onTrackChangesOfFile: (@Sendable (URL) throws -> FileReference)?
  public var onSubscribeToContentChange: (@Sendable (FileReference, @Sendable @escaping (String?) -> Void) -> Void)?
  public var onApply: (@Sendable (FileChange) async throws -> Void)?

  public func trackChangesOfFile(at url: URL) throws -> FileReference {
    if let onTrackChangesOfFile {
      return try onTrackChangesOfFile(url)
    }
    return MockFileReference(path: url, currentContent: currentContent ?? "")
  }

  public func apply(change: FileChange) async throws {
    if let onApply {
      try await onApply(change)
    }
  }

  public func subscribeToContentChange(to fileRef: FileReference, onChange: @escaping FileChangeSubscriber) {
    if let onSubscribeToContentChange {
      onSubscribeToContentChange(fileRef, onChange)
    }
  }
}

// MARK: - MockFileReference

@ThreadSafe
public final class MockFileReference: FileReference {

  public init(path: URL, currentContent: String) {
    self.path = path
    self.currentContent = currentContent
  }

  public let path: URL
  public var currentContent: String

}
#endif
