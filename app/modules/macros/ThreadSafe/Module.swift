Target.macroModule(
  name: "ThreadSafe",
  dependencies: [
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    "ConcurrencyFoundation",
    "ThreadSafeMacro",
  ],
  macroDependencies: [
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    "ConcurrencyFoundation",
  ],
  testDependencies: [
    .product(name: "MacroTesting", package: "swift-macro-testing"),
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    "ThreadSafeMacro",
  ])
