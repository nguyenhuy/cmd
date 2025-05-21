Target.module(
  name: "SettingsService",
  dependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "SettingsServiceInterface",
    "SharedValuesFoundation",
    "ThreadSafe",
  ],
  testDependencies: [
    "ConcurrencyFoundation",
    "FoundationInterfaces",
    "SettingsServiceInterface",
    "SharedValuesFoundation",
    "SwiftTesting",
  ])
