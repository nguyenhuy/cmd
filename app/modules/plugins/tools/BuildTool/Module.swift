Target.module(
  name: "BuildTool",
  dependencies: [
    "AppFoundation",
    "CodePreview",
    "ConcurrencyFoundation",
    "DLS",
    "JSONFoundation",
    "ServerServiceInterface",
    "ToolFoundation",
    "XcodeControllerServiceInterface",
  ],
  testDependencies: [
    "SwiftTesting",
    "ToolFoundation",
    "XcodeControllerServiceInterface",
  ])
