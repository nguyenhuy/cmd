// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "ExecuteCommandTool",
  dependencies: [
    "AppFoundation",
    "CodePreview",
    "ConcurrencyFoundation",
    "DLS",
    "JSONFoundation",
    "ServerServiceInterface",
    "ShellServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "LLMServiceInterface",
    "ServerServiceInterface",
    "ShellServiceInterface",
    "SwiftTesting",
  ])
