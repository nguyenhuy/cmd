// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "CheckpointServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "AppFoundation",
    "ConcurrencyFoundation",
  ],
  testDependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "SwiftTesting",
  ])
