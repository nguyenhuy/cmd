// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
import XcodeControllerServiceInterface
@testable import BuildTool

// MARK: - BuildToolEncodingTests

struct BuildToolEncodingTests {

  // MARK: - Tool Use Encoding/Decoding Tests

  @Test("Tool Use encoding/decoding - test build")
  func test_toolUseEncodingDecodingTest() throws {
    let tool = BuildTool()
    let input = BuildTool.Use.Input(for: .test)
    let use = tool.use(toolUseId: "build-test-789", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "build",
        "input": {
          "for": "test"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "build-test-789"
      }
      """)
  }

  @Test("Tool Use encoding/decoding - run build")
  func test_toolUseEncodingDecodingRun() throws {
    let tool = BuildTool()
    let input = BuildTool.Use.Input(for: .run)
    let use = tool.use(toolUseId: "build-run-101", input: input, context: toolExecutionContext)

    try testDecodingEncoding(of: use, """
      {
        "callingTool": "build",
        "input": {
          "for": "run"
        },
        "status": {
          "status": "notStarted"
        },
        "toolUseId": "build-run-101"
      }
      """)
  }
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
