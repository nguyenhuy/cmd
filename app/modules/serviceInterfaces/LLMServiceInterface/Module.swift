Target.module(
  name: "LLMServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ChatFoundation",
    "ConcurrencyFoundation",
    "JSONFoundation",
    "LLMFoundation",
    "ServerServiceInterface",
    "ThreadSafe",
    "ToolFoundation",
  ],
  testDependencies: [])
