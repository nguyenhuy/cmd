Target.module(
  name: "ChatHistoryServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ChatFeatureInterface",
    "ThreadSafe",
  ],
  testDependencies: [])
