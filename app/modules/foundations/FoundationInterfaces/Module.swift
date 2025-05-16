// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "FoundationInterfaces",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "JSONFoundation",
    "ThreadSafe",
  ],
  testDependencies: [])
