Target.module(
  name: "ChatHistoryService",
  dependencies: [
    .product(name: "GRDB", package: "GRDB.swift"),
    "ChatHistoryServiceInterface",
    "DependencyFoundation",
    "FoundationInterfaces",
    "LLMServiceInterface",
    "LoggingServiceInterface",
  ],
  testDependencies: [])
