// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
