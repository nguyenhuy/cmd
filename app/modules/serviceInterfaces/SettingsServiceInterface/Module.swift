Target.module(
  name: "SettingsServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ConcurrencyFoundation",
  ],
  testDependencies: [
    "SwiftTesting",
  ])
