Target.module(
  name: "FileSuggestionService",
  dependencies: [
    .product(name: "Ifrit", package: "Ifrit"),
    .product(name: "XcodeProj", package: "XcodeProj"),
    "AppFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "FileSuggestionServiceInterface",
    "FoundationInterfaces",
    "ShellServiceInterface",
    "ThreadSafe",
    "XcodeObserverServiceInterface",
  ],
  testDependencies: [
    "ConcurrencyFoundation",
    "FoundationInterfaces",
    "ShellServiceInterface",
    "SwiftTesting",
    "XcodeObserverServiceInterface",
  ],
  testResources: [
    .copy("resources/"),
  ])
