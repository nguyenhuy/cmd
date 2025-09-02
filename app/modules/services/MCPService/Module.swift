Target.module(
  name: "MCPService",
  dependencies: [
    "AppFoundation",
    "DependencyFoundation",
    "FoundationInterfaces",
    "JSONFoundation",
    "LoggingServiceInterface",
    "MCPServiceInterface",
    "SettingsServiceInterface",
  ],
  testDependencies: [
    "MCPServiceInterface",
    "SwiftTesting",
  ])
