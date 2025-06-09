Target.module(
  name: "ChatHistoryService",
  dependencies: [
    .product(name: "GRDB", package: "GRDB.swift"),
    "ChatFeatureInterface",
    "ChatHistoryServiceInterface",
    "CheckpointServiceInterface",
    "DependencyFoundation",
    "FoundationInterfaces",
    "LLMServiceInterface",
    "LoggingServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "ChatFeatureInterface",
    "ChatHistoryServiceInterface",
    "ConcurrencyFoundation",
    "FoundationInterfaces",
    "LLMServiceInterface",
    "SwiftTesting",
    "ToolFoundation",
  ])
