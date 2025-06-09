// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
