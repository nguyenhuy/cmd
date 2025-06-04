Target.module(
  name: "DLS",
  dependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "LoggingServiceInterface",
    "ServerServiceInterface",
  ],
  resources: [
    .process("Resources/fileIcons"),
  ],
  testDependencies: [])
