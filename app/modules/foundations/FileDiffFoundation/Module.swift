// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
