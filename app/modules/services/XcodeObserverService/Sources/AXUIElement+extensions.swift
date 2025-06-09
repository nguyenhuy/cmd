// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import AppKit
import Foundation

extension AXUIElement {
  var workspaceURL: URL? {
    for child in children {
      if
        let description = child.description,
        description.starts(with: "/"), description.count > 1
      {
        let path = description
        let trimmedNewLine = path.trimmingCharacters(in: .newlines)
        return URL(fileURLWithPath: trimmedNewLine)
      }
    }
    return nil
  }

  var documentURL: URL? {
    // fetch file path of the frontmost window of Xcode through Accessibility API.
    let path = document
    if let path = path?.removingPercentEncoding {
      let url = URL(
        fileURLWithPath: path
          .replacingOccurrences(of: "file://", with: ""))
      if url.pathExtension == "playground", url.isDirectory {
        return url.appendingPathComponent("Contents.swift")
      }
      return url
    }
    return nil
  }
}

extension URL {
  var isDirectory: Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
  }
}
