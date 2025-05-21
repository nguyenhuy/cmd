Target.module(
  name: "ServerServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "AppFoundation",
    "ConcurrencyFoundation",
    "JSONFoundation",
  ],
  testDependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "SwiftTesting",
  ])
