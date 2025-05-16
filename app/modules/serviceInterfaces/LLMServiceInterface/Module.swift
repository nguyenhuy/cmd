// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "LLMServiceInterface",
  dependencies: [
    .product(name: "Dependencies", package: "swift-dependencies"),
    "ConcurrencyFoundation",
    "JSONFoundation",
    "ServerServiceInterface",
    "ThreadSafe",
    "ToolFoundation",
  ],
  testDependencies: [])
