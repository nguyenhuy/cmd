Target.module(
  name: "AppUpdateService",
  dependencies: [
    .product(name: "Sparkle", package: "Sparkle"),
    "AppFoundation",
    "AppUpdateServiceInterface",
    "DependencyFoundation",
    "LoggingServiceInterface",
    "SettingsServiceInterface",
    "ThreadSafe",
  ],
  testDependencies: [])
