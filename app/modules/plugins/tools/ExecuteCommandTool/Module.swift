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
    "ThreadSafe",
    "ToolFoundation",
  ],
  testDependencies: [
    "LLMServiceInterface",
    "ServerServiceInterface",
    "ShellServiceInterface",
    "SwiftTesting",
  ])
