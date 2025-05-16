// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftSyntax

extension URL {
  public var canonicalURL: URL {
    var path = path.replacingOccurrences(of: "./", with: "")
    if !path.hasSuffix("/") {
      path += "/"
    }
    return URL(fileURLWithPath: path).absoluteURL
  }

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

extension ArrayElementListSyntax {
  func appending(contentOf: [ArrayElementSyntax]) -> ArrayElementListSyntax {
    var result = self
    result.append(contentsOf: contentOf)
    return result
  }
}

extension Array {

  public func uniqueSorted(by identifier: (Element) -> some Equatable & Comparable) -> [Element] {
    let sorted: [Element?] = sorted { identifier($0) < identifier($1) }
    return zip(sorted, [nil] + sorted)
      .filter { $0.0.map(identifier) != $0.1.map(identifier) }
      .compactMap(\.0)
  }

  mutating func uniqueSort(by identifier: (Element) -> some Equatable & Comparable) {
    self = uniqueSorted(by: identifier)
  }
}

extension String {
  public func resolve(with base: String) -> String {
    if hasPrefix("/") {
      return self
    }
    if base.hasSuffix("/") {
      return base + self
    }
    return base + "/" + self
  }
}
