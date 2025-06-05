Target.module(
  name: "SettingsFeature",
  dependencies: [
    "AppUpdateServiceInterface",
    "ChatFoundation",
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
