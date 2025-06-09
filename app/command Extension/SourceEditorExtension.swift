// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppExtension
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import SharedValuesFoundation
import XcodeKit

final class SourceEditorExtension: NSObject, XCSourceEditorExtension {

  var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
    defaultLogger.log("creating commandDefinitions")
    let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    return [
      ApplyEditCommand(),
      OpenInCursorCommand(),
    ].map { $0.makeCommandDefinition(identifierPrefix: bundleIdentifier) }
  }

  func extensionDidFinishLaunching() {
    #if RELEASE
    if AppExtensionScope.shared.sharedUserDefaults.bool(forKey: SharedKeys.pointReleaseXcodeExtensionToDebugApp) != true {
      openContainingAppIfNecessary()
    }
    #endif
  }

  private func openContainingAppIfNecessary() {
    do {
      try OpenHostApp.openHostApp()
    } catch {
      defaultLogger.error("Error opening containing application: \(error)")
    }
  }

}
