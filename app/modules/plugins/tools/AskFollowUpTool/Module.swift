Target.module(
  name: "AskFollowUpTool",
  dependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "DLS",
    "JSONFoundation",
    "ServerServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "LSTool",
    "ServerServiceInterface",
    "SwiftTesting",
  ])
