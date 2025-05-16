// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

Target.module(
  name: "ReadFileTool",
  dependencies: [
    "CodePreview",
    "DLS",
    "FoundationInterfaces",
    "JSONFoundation",
    "ServerServiceInterface",
    "ToolFoundation",
  ],
  testDependencies: [
    "FoundationInterfaces",
    "LLMServiceInterface",
    "SwiftTesting",
  ])
