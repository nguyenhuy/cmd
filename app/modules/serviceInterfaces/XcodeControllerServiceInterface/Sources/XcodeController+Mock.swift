// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import FileDiffFoundation
import Foundation
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockXcodeController: XcodeController {

  public init() { }

  public var onApplyFileChange: (@Sendable (FileChange) -> Void)?

  public var onBuild: (@Sendable (URL, BuildType) async throws -> [BuildMessage])?

  public func apply(fileChange: FileChange) async throws {
    onApplyFileChange?(fileChange)
  }

  public func build(project: URL, buildType: BuildType) async throws -> [BuildMessage] {
    if let onBuild {
      try await onBuild(project, buildType)
    } else {
      []
    }
  }

}
#endif
