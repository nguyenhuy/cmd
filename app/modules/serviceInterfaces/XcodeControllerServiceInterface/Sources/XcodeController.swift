// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@_exported import FileDiffTypesFoundation
import Foundation

// MARK: - XcodeController

public protocol XcodeController: Sendable {
  func apply(fileChange: FileChange) async throws
}

// MARK: - XcodeControllerProviding

public protocol XcodeControllerProviding {
  var xcodeController: XcodeController { get }
}
