// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Read the Package.swift file and find all the defined targets with information about their dependencies.
public final class ExtractModuleInfo: SyntaxVisitor {

  public init(packageDirPath: URL) {
    self.packageDirPath = packageDirPath
    super.init(viewMode: .sourceAccurate)
  }

  public private(set) var targetInfo = [TargetInfo]()

  public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    guard
      let base = node.calledExpression.as(MemberAccessExprSyntax.self),
      base.declName.baseName.text == "macro" ||
      base.declName.baseName.text == "target" ||
      base.declName.baseName.text == "testTarget" ||
      base.declName.baseName.text == "macroModule" ||
      base.declName.baseName.text == "module"
    else {
      return super.visit(node)
    }

    guard let name = findStringArgument(in: node.arguments, label: "name"), !name.isEmpty else {
      return super.visit(node)
    }
    let path = findStringArgument(in: node.arguments, label: "path")?.resolve(with: packageDirPath.path)
    let dependencies = extractDependencies(in: node.arguments)

    if base.declName.baseName.text == "module" || base.declName.baseName.text == "macroModule" {
      guard let path else {
        fatalError("Modules should have a path. Missing for \(name)")
      }
      let sourcesPath = "\(path)/Sources"
      targetInfo.append(TargetInfo(
        name: name,
        path: sourcesPath,
        type: .target,
        dependencies: dependencies ?? [],
        raw: node,
        modulePath: path))
      if let testDependencies = extractDependencies(in: node.arguments, key: "testDependencies") {
        targetInfo.append(TargetInfo(
          name: "\(name)Tests",
          path: "\(path)/Tests",
          type: .testTarget,
          dependencies: testDependencies + [DependencyInfo(raw: "\"\(raw: name)\"", name: name, package: nil)],
          raw: node,
          modulePath: path))
      }
      if base.declName.baseName.text == "macroModule" {
        targetInfo.append(TargetInfo(
          name: "\(name)Macro",
          path: "\(path)/Sources",
          type: .macro,
          dependencies: extractDependencies(in: node.arguments, key: "macroDependencies") ?? [],
          raw: node,
          modulePath: path))
      }
    } else {
      guard let targetType = TargetInfo.TargetType(rawValue: base.declName.baseName.text) else {
        fatalError("Unknown target type: \(base.declName.baseName.text)")
      }
      targetInfo.append(TargetInfo(name: name, path: path, type: targetType, dependencies: dependencies ?? [], raw: node))
    }

    return .skipChildren
  }

  private let packageDirPath: URL

  /// Extracts dependencies from `dependencies: [ ... ]`, returning an array of `DependencyInfo`.
  private func extractDependencies(in argumentList: LabeledExprListSyntax, key: String = "dependencies") -> [DependencyInfo]? {
    var result: [DependencyInfo]?

    for arg in argumentList {
      guard let argLabel = arg.label, argLabel.text == key else { continue }
      result = []
      guard let arrayExpr = arg.expression.as(ArrayExprSyntax.self) else { break }

      for depElement in arrayExpr.elements {
        if let dependencyInfo = depElement.expression.dependencyInfo {
          result?.append(dependencyInfo)
        }
      }
    }
    return result
  }
}
