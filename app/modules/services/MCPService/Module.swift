Target.module(
  name: "MCPService",
  dependencies: [
    .product(name: "MCP", package: "swift-sdk"),
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
