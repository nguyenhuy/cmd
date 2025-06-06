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
    .process("Resources/cmd-logo.svg"),
  ],
  testDependencies: [])
