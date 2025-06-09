// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Finds a string literal argument for the given label (like `name: "App"`).
/// Returns its contents without the quotes, or nil if not found.
public func findStringArgument(
  in argumentList: LabeledExprListSyntax,
  label: String)
  -> String?
{
  for arg in argumentList {
    guard let argLabel = arg.label, argLabel.text == label else { continue }
    if
      let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
      let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
    {
      return segment.content.text
    }
  }
  return nil
}

func makeStringLiteralExpr(_ stringValue: String) -> ExprSyntax {
  makeExpr("\"\(stringValue)\"")
}

func makeExpr(_ source: String) -> ExprSyntax {
  let sf = Parser.parse(source: source)
  guard
    let firstItem = sf.statements.first,
    let expr = firstItem.item.as(ExprSyntax.self)
  else {
    fatalError("Could not parse string literal: \(source)")
  }
  return expr
}

/// Builds an array expression from a list of strings.
/// If a string starts with `"product("`, we treat it as an identifier expression.
/// Otherwise we treat it as a string literal.
func makeArrayExprSyntax(from items: [ExprSyntax]) -> ArrayExprSyntax {
  let leftSq = TokenSyntax.leftSquareToken()
  let rightSq = TokenSyntax.rightSquareToken()

  // Convert each string into an ArrayElementSyntax
  let elementList = items.enumerated().map { idx, item -> ArrayElementSyntax in
    return ArrayElementSyntax(
      leadingTrivia: idx == 0 ? .newline : nil,
      expression: item.trimmed,
      trailingComma: TokenSyntax.commaToken(trailingTrivia: .newline))
  }

  let arrayElementList = ArrayElementListSyntax(elementList)
  return ArrayExprSyntax(
    leftSquare: leftSq,
    elements: arrayElementList,
    rightSquare: rightSq)
}
