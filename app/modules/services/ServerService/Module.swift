// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "ServerService",
  dependencies: [
    "AppEventServiceInterface",
    "AppFoundation",
    "DependencyFoundation",
    "ExtensionEventsInterface",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "ServerServiceInterface",
    "ThreadSafe",
  ],
  resources: [.process("Resources")],
  testDependencies: [
    "JSONFoundation",
    "ServerServiceInterface",
    "SwiftTesting",
  ])
