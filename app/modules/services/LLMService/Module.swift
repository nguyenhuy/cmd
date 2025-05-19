// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "LLMService",
  dependencies: [
    .product(name: "JSONScanner", package: "JSONScanner"),
    .product(name: "SwiftOpenAI", package: "SwiftOpenAI"),
    "AppFoundation",
    "ConcurrencyFoundation",
    "DependencyFoundation",
    "JSONFoundation",
    "LLMServiceInterface",
    "LoggingServiceInterface",
    "ServerServiceInterface",
    "SettingsServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "AppFoundation",
    "ConcurrencyFoundation",
    "JSONFoundation",
    "LLMServiceInterface",
    "ServerServiceInterface",
    "SettingsServiceInterface",
    "SwiftTesting",
    "ToolFoundation",
  ])
