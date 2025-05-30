// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

extension URL {
  /// Given a path, that might be relative to the project root or absolute, resolve it to an absolute path.
  public func resolve(from root: URL) -> URL {
    path.resolvePath(from: root)
  }

  /// Whether a given path is within the project root.
  public func isWithin(root: URL) -> Bool {
    path.starts(with: root.path)
  }

  /// The path relative to the given reference URL.
  public func pathRelative(to reference: URL) -> String {
    var commonPathComponentsCount = 0
    for (a, b) in zip(self.pathComponents, reference.pathComponents) {
      if a != b {
        break
      } else {
        commonPathComponentsCount += 1
      }
    }

    let pathComponents = [String](repeating: "..", count: reference.pathComponents.count - commonPathComponentsCount)
      + pathComponents.dropFirst(commonPathComponentsCount)

    return pathComponents.joined(separator: "/")
  }

}

extension String {
  /// Given a path, that might be relative to the project root or absolute, resolve it to an absolute path.
  public func resolvePath(from base: URL?) -> URL {
    guard let base else {
      return URL(fileURLWithPath: self).standardized
    }
    if hasPrefix("/") {
      return URL(fileURLWithPath: self)
    } else {
      return base.appendingPathComponent(self).standardized
    }
  }
}
