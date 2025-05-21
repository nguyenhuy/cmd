Target.module(
  name: "LLMServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ConcurrencyFoundation",
    "JSONFoundation",
    "ServerServiceInterface",
    "ThreadSafe",
    "ToolFoundation",
  ],
  testDependencies: [])
