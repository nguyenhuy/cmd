// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftParser
import SwiftSyntax

// MARK: - GenerateModulePackage

/// Generate the Package.swift file for one module.
public final class GenerateModulePackage {

  public init(modulePath: String, allTargets: [String: TargetInfo], basePackageSource: SourceFileSyntax) throws {
    self.modulePath = URL(fileURLWithPath: modulePath).canonicalURL
    self.allTargets = allTargets
    self.basePackageSource = basePackageSource
  }

  public func run() throws {
    let targets = allTargets
    let focussedTargets = targets.values.filter { $0.modulePath == modulePath }

    var selectedTargets = focussedTargets.reduce(into: [String: TargetInfo]()) { result, target in
      result[target.name] = target
    }
    var externalDependencies = Set<String>()

    // Add all dependencies, not including transitives.
    var needsDependencies = focussedTargets
    while needsDependencies.count > 0 {
      let target = needsDependencies.removeFirst()
      let moduleTargets = targets.values.filter { $0.modulePath == target.modulePath }

      for dependency in moduleTargets.flatMap(\.dependencies) {
        if selectedTargets[dependency.name] != nil {
          // Dependency already added
          continue
        }
        if let package = dependency.package {
          externalDependencies.insert(package.packageName)
          continue
        }
        guard let dependencyTarget = targets[dependency.name] else {
          fatalError("Target \(dependency.name) not found")
        }
        selectedTargets[dependency.name] = dependencyTarget
      }
    }

    let packagePath = modulePath.appendingPathComponent("Package.swift")
    let rewriter = try AddTargetToPackage(
      source: basePackageSource,
      packageDirPath: modulePath,
      modules: [modulePath.path])
    var rewrittenFile = rewriter.rewrite()

    rewrittenFile = UpdatePackage(
      packagePath: packagePath,
      name: modulePath.lastPathComponent,
      focussedTargetNames: focussedTargets.filter { $0.type == .target }.map(\.name),
      internalDependencies: selectedTargets.values.filter { $0.modulePath != modulePath },
      externalDependencies: externalDependencies)
      .visit(rewrittenFile)

    try """
      // This file is generated. Do not modify directly.

      \(rewrittenFile.description)
      """
    .write(
      to: URL(fileURLWithPath: packagePath.path),
      atomically: true,
      encoding: .utf8)
  }

  let modulePath: URL
  let allTargets: [String: TargetInfo]
  let basePackageSource: SourceFileSyntax

}

// MARK: - UpdatePackage

final class UpdatePackage: SyntaxRewriter {

  init(
    packagePath: URL,
    name: String,
    focussedTargetNames: [String],
    internalDependencies: [TargetInfo],
    externalDependencies: Set<String>)
  {
    self.packagePath = packagePath
    self.name = name
    self.focussedTargetNames = focussedTargetNames
    self.externalDependencies = externalDependencies
    self.internalDependencies = internalDependencies
  }

  let focussedTargetNames: [String]
  let externalDependencies: Set<String>
  let internalDependencies: [TargetInfo]
  let packagePath: URL
  let name: String

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard
      node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Package"
    else {
      return super.visit(node)
    }

    guard
      let nameArgumentIdx = node.arguments.firstIndex(where: { $0.label?.text == "name" }),
      let productsArgumentIdx = node.arguments.firstIndex(where: { $0.label?.text == "products" }),
      let dependenciesArgumentIdx = node.arguments.firstIndex(where: { $0.label?.text == "dependencies" })
    else {
      fatalError("missing products or dependencies argument in Package")
    }
    var arguments = node.arguments
    var newNameArg = LabeledExprSyntax(label: "name", expression: makeExpr("\"\(name)\""))
    newNameArg.trailingComma = .commaToken()
    arguments.remove(at: nameArgumentIdx)
    arguments.insert(newNameArg, at: nameArgumentIdx)

    let newProducts = makeExpr("""
      [
        \(focussedTargetNames.map { ".library(name: \"\($0)\", targets: [\"\($0)\"])" }.joined(separator: ",\n"))
      ]
      """)
    var newProductArg = LabeledExprSyntax(label: "products", expression: newProducts)
    newProductArg.trailingComma = .commaToken()
    arguments.remove(at: productsArgumentIdx)
    arguments.insert(newProductArg, at: productsArgumentIdx)

    if let dependencies = arguments[dependenciesArgumentIdx].expression.as(ArrayExprSyntax.self) {
      arguments[dependenciesArgumentIdx] = arguments[dependenciesArgumentIdx].with(
        \.expression,
        ExprSyntax(dependencies.with(
          \.elements,
          dependencies.elements
            .filter { dep in !externalDependencies.filter { dep.description.contains("/\($0)") }.isEmpty }
            .appending(
              contentOf: internalDependencies
                .uniqueSorted(by: \.path)
                .compactMap { dep -> ArrayElementSyntax? in
                  guard let modulePath = dep.modulePath else { return nil }
                  return ArrayElementSyntax(
                    leadingTrivia: .newline,
                    expression: makeExpr(
                      ".package(path: \"\(modulePath.pathRelative(to: packagePath.deletingLastPathComponent()))\"),"),
                    trailingComma: .commaToken())
                }))))
    }

    return ExprSyntax(super.visit(node.with(\.arguments, arguments)))
  }
}
