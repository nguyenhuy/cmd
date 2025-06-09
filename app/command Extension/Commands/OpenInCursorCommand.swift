// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AccessibilityFoundation
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import SharedValuesFoundation
import XcodeKit

final class OpenInCursorCommand: CommandType, @unchecked Sendable {
  override var name: String { "Open in Cursor" }

  /// This timeout is a bit elevated as the command usually takes just a bit over 1s.
  override var timeoutAfter: TimeInterval { 5 }

  override func handle(_: XCSourceEditorCommandInvocation) async throws {
    let response: EmptyResponse = try await LocalServer().send(command: ExtensionCommandKeys.openInCursor, input: EmptyInput())
    _ = response
  }
}
