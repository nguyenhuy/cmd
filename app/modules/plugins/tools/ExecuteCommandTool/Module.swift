Target.module(
  name: "ExecuteCommandTool",
  dependencies: [
    "AppFoundation",
    "CodePreview",
    "ConcurrencyFoundation",
    "DLS",
    "JSONFoundation",
    "ServerServiceInterface",
    "ShellServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "LLMServiceInterface",
    "ServerServiceInterface",
    "ShellServiceInterface",
    "SwiftTesting",
  ])
