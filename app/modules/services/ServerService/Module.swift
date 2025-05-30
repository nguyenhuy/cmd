Target.module(
  name: "ServerService",
  dependencies: [
    "AppEventServiceInterface",
    "AppFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "ExtensionEventsInterface",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "ServerServiceInterface",
    "ThreadSafe",
  ],
  resources: [.process("Resources")],
  testDependencies: [
    "AppFoundation",
    "JSONFoundation",
    "ServerServiceInterface",
    "SwiftTesting",
  ])
