Target.module(
  name: "SettingsServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "AppFoundation",
    "ConcurrencyFoundation",
    "LLMFoundation",
  ],
  testDependencies: [
    "SwiftTesting",
  ])
