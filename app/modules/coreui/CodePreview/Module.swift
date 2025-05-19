// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
