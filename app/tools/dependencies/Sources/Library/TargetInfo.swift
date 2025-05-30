// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftSyntax

// MARK: - DependencyInfo

/// Represents a package dependency with both its raw syntax expression and normalized name.
public struct DependencyInfo {
  /// The original syntax expression (e.g. `"SomeTarget"` or `product(name: "KeyboardShortcuts", package: "...")`)
  let raw: ExprSyntax

  /// The normalized dependency name (e.g. "SomeTarget" or "KeyboardShortcuts")
  public let name: String

  public let package: PackageDependencyInfo?

  public struct PackageDependencyInfo {
    public let packageName: String
    public let procuct: String
  }
}

// MARK: - TargetInfo

public struct TargetInfo {

  init(
    name: String,
    path: String?,
    type: TargetType,
    dependencies: [DependencyInfo],
    raw: FunctionCallExprSyntax,
    modulePath: String? = nil)
  {
    if let path, !path.isEmpty {
      self.path = path
    } else {
      // Use the same default values as SPM.
      if name.hasSuffix("Tests") {
        self.path = "Tests/\(name)"
      } else {
        self.path = "Sources/\(name)"
      }
    }
    self.modulePath = modulePath.map { URL(fileURLWithPath: $0).canonicalURL }
    self.name = name
    self.type = type
    self.dependencies = dependencies
    self.raw = raw
  }

  public enum TargetType: String {
    case target
    case testTarget
    case macro
  }

  public let name: String
  public let path: String
  public let type: TargetType
  public let modulePath: URL?
  public let dependencies: [DependencyInfo]

  let raw: FunctionCallExprSyntax
}
