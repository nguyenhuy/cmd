// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
