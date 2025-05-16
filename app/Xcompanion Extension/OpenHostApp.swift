// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import LoggingServiceInterface

enum OpenHostApp {
  // TODO: make this async and wait for the process to be running
  public static func openHostApp() throws {
    guard let bundleIdentifier = Bundle.main.object(forInfoDictionaryKey: "HostAppBundleIdentifier") as? String else {
      let errorMessage = "Could not read `HostAppBundleIdentifier` from the plist."
      defaultLogger.error(errorMessage)
      throw XcodeExtensionError(message: errorMessage)
    }

    let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    guard let appURL else {
      let errorMessage = "Xcompanion could not be located in the Applications folder."
      defaultLogger.error(errorMessage)
      throw XcodeExtensionError(message: errorMessage)
    }
    defaultLogger.info("Opening Xcompanion from the extension")

    let url = URL(fileURLWithPath: appURL.path, isDirectory: true)
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
  }
}
