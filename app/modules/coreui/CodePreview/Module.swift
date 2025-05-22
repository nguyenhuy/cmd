Target.module(
  name: "CodePreview",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "AppFoundation",
    "ConcurrencyFoundation",
    "DLS",
    "FileDiffFoundation",
    "FileDiffTypesFoundation",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "XcodeControllerServiceInterface",
    "XcodeObserverServiceInterface",
  ],
  testDependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "FileDiffFoundation",
    "FileDiffTypesFoundation",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "SwiftTesting",
    "XcodeControllerServiceInterface",
  ])
