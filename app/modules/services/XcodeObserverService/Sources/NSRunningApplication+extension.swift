// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Dependencies
import FoundationInterfaces

extension NSRunningApplication {
  var version: String? {
    guard
      let plistPath = bundleURL?
        .appendingPathComponent("Contents")
        .appendingPathComponent("version.plist")
        .path
    else { return nil }
    @Dependency(\.fileManager) var fileManager
    guard let plistData = try? fileManager.read(dataFrom: URL(fileURLWithPath: plistPath)) else { return nil }
    var format = PropertyListSerialization.PropertyListFormat.xml
    guard
      let plistDict = try? PropertyListSerialization.propertyList(
        from: plistData,
        options: .mutableContainersAndLeaves,
        format: &format) as? [String: AnyObject]
    else { return nil }
    return plistDict["CFBundleShortVersionString"] as? String
  }
}
