Target.module(
  name: "SettingsFeature",
  dependencies: [
    "AppUpdateServiceInterface",
    "ConcurrencyFoundation",
    "DLS",
    "FoundationInterfaces",
    "LLMFoundation",
    "SettingsServiceInterface",
  ],
  testDependencies: [
    "FoundationInterfaces",
    "LLMFoundation",
    "SettingsServiceInterface",
    "SwiftTesting",
  ])
