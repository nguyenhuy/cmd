// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "SettingsService",
  dependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "SettingsServiceInterface",
    "SharedValuesFoundation",
    "ThreadSafe",
  ],
  testDependencies: [
    "ConcurrencyFoundation",
    "FoundationInterfaces",
    "SettingsServiceInterface",
    "SharedValuesFoundation",
    "SwiftTesting",
  ])
