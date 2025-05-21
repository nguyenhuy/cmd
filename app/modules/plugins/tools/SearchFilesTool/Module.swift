Target.module(
  name: "SearchFilesTool",
  dependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "DLS",
    "JSONFoundation",
    "ServerServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "ServerServiceInterface",
    "SwiftTesting",
  ])
