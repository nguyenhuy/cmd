Target.module(
  name: "ReadFileTool",
  dependencies: [
    "CodePreview",
    "ConcurrencyFoundation",
    "DLS",
    "FoundationInterfaces",
    "HighlighterServiceInterface",
    "JSONFoundation",
    "ServerServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "FoundationInterfaces",
    "LLMServiceInterface",
    "SwiftTesting",
  ])
