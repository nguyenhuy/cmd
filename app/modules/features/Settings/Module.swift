Target.module(
  name: "SettingsFeature",
  dependencies: [
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
