// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import FileDiffFoundation
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockXcodeController: XcodeController {

  public init() { }

  public var onApplyFileChange: (@Sendable (FileChange) -> Void)?

  public func apply(fileChange: FileChange) async throws {
    onApplyFileChange?(fileChange)
  }

}
#endif
