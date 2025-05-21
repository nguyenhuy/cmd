Target.module(
  name: "ToolFoundation",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "AppFoundation",
    "ChatFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "JSONFoundation",
    "ThreadSafe",
  ],
  testDependencies: [])
