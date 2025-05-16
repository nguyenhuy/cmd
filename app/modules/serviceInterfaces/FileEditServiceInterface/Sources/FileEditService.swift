// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import FileDiffTypesFoundation
import Foundation

// MARK: - FileEditService

public protocol FileEditService: Sendable {
  func trackChangesOfFile(at path: URL) throws -> FileReference
  func apply(change: FileChange) async throws
  func subscribeToContentChange(to fileRef: FileReference, onChange: @escaping FileChangeSubscriber)
}

public typealias FileChangeSubscriber = @Sendable (String?) -> Void

// MARK: - FileEditServiceProviding

public protocol FileEditServiceProviding {
  var fileEditService: FileEditService { get }
}

// MARK: - FileReference

public protocol FileReference: Sendable {
  var path: URL { get }
  var currentContent: String { get throws }
}
