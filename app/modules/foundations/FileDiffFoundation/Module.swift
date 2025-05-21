Target.module(
  name: "FileDiffFoundation",
  dependencies: [
    .product(name: "HighlightSwift", package: "highlightswift"),
    "AppFoundation",
    "FileDiffTypesFoundation",
    "LoggingServiceInterface",
  ],
  testDependencies: [
    .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
    "FileDiffTypesFoundation",
  ],
  testExclude: ["__Snapshots__"])
