// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import SwiftTesting
import Testing
import ToolFoundation
@testable import ExecuteCommandTool

// MARK: - ExecuteCommandToolEncodingTests

enum ExecuteCommandToolEncodingTests {

  struct InputEncoding {

    // MARK: - Input Encoding/Decoding Tests

    @Test("Input encoding/decoding - basic command")
    func test_inputEncodingDecodingBasic() throws {
      let input = ExecuteCommandTool.Use.Input(
        command: "ls -la",
        cwd: nil,
        canModifySourceFiles: false,
        canModifyDerivedFiles: false)

      try testEncodingDecoding(input, """
        {
          "command": "ls -la",
          "canModifySourceFiles": false,
          "canModifyDerivedFiles": false
        }
        """)
    }

    @Test("Input encoding/decoding - with working directory")
    func test_inputEncodingDecodingWithCwd() throws {
      let input = ExecuteCommandTool.Use.Input(
        command: "git status",
        cwd: "/path/to/project",
        canModifySourceFiles: false,
        canModifyDerivedFiles: true)

      try testEncodingDecoding(input, """
        {
          "command": "git status",
          "cwd": "/path/to/project",
          "canModifySourceFiles": false,
          "canModifyDerivedFiles": true
        }
        """)
    }

    @Test("Input encoding/decoding - with permissions")
    func test_inputEncodingDecodingWithPermissions() throws {
      let input = ExecuteCommandTool.Use.Input(
        command: "swift build",
        cwd: "/source",
        canModifySourceFiles: true,
        canModifyDerivedFiles: true)

      try testEncodingDecoding(input, """
        {
          "command": "swift build",
          "cwd": "/source",
          "canModifySourceFiles": true,
          "canModifyDerivedFiles": true
        }
        """)
    }

    @Test("Input encoding/decoding - complex command")
    func test_inputEncodingDecodingComplex() throws {
      let input = ExecuteCommandTool.Use.Input(
        command: "find . -name \"*.swift\" -exec grep -l \"TODO\" {} \\;",
        cwd: "/project/src",
        canModifySourceFiles: false,
        canModifyDerivedFiles: false)

      try testEncodingDecoding(input, """
        {
          "command": "find . -name \\"*.swift\\" -exec grep -l \\"TODO\\" {} \\\\;",
          "cwd": "/project/src",
          "canModifySourceFiles": false,
          "canModifyDerivedFiles": false
        }
        """)
    }

    @Test("Input encoding/decoding - command with quotes and special chars")
    func test_inputEncodingDecodingSpecialChars() throws {
      let input = ExecuteCommandTool.Use.Input(
        command: "echo \"Hello, World!\" && echo 'Single quotes' | grep World",
        cwd: nil,
        canModifySourceFiles: false,
        canModifyDerivedFiles: false)

      try testEncodingDecoding(input, """
        {
          "command": "echo \\"Hello, World!\\" && echo 'Single quotes' | grep World",
          "canModifySourceFiles": false,
          "canModifyDerivedFiles": false
        }
        """)
    }
  }

  struct OutputEncoding {

    // MARK: - Output Encoding/Decoding Tests

    @Test("Output encoding/decoding - successful execution")
    func test_outputEncodingDecodingSuccess() throws {
      let output = ExecuteCommandTool.Use.Output(
        output: "Build succeeded\nAll tests passed",
        exitCode: 0)

      try testEncodingDecoding(output, """
        {
          "output": "Build succeeded\\nAll tests passed",
          "exitCode": 0
        }
        """)
    }

    @Test("Output encoding/decoding - failed execution")
    func test_outputEncodingDecodingFailure() throws {
      let output = ExecuteCommandTool.Use.Output(
        output: "Error: Command not found\nUsage: command [options]",
        exitCode: 127)

      try testEncodingDecoding(output, """
        {
          "output": "Error: Command not found\\nUsage: command [options]",
          "exitCode": 127
        }
        """)
    }

    @Test("Output encoding/decoding - empty output")
    func test_outputEncodingDecodingEmpty() throws {
      let output = ExecuteCommandTool.Use.Output(
        output: nil,
        exitCode: 0)

      try testEncodingDecoding(output, """
        {
          "exitCode": 0
        }
        """)
    }

    @Test("Output encoding/decoding - long output")
    func test_outputEncodingDecodingLong() throws {
      let longOutput = """
        Line 1: Starting process...
        Line 2: Initializing components
        Line 3: Loading configuration
        Line 4: Connecting to services
        Line 5: Processing data...
        Line 6: Finalizing results
        Line 7: Process completed successfully
        """

      let output = ExecuteCommandTool.Use.Output(
        output: longOutput,
        exitCode: 0)

      try testEncodingDecoding(output, """
        {
          "output": "Line 1: Starting process...\\nLine 2: Initializing components\\nLine 3: Loading configuration\\nLine 4: Connecting to services\\nLine 5: Processing data...\\nLine 6: Finalizing results\\nLine 7: Process completed successfully",
          "exitCode": 0
        }
        """)
    }

    @Test("Output encoding/decoding - with unicode and special chars")
    func test_outputEncodingDecodingUnicode() throws {
      let output = ExecuteCommandTool.Use.Output(
        output: "✅ Tests passed\n❌ Build failed\n🚀 Deployment ready\n中文测试",
        exitCode: 1)

      try testEncodingDecoding(output, """
        {
          "output": "✅ Tests passed\\n❌ Build failed\\n🚀 Deployment ready\\n中文测试",
          "exitCode": 1
        }
        """)
    }
  }

  struct ToolUseEncoding {

    // MARK: - Tool Use Encoding/Decoding Tests

    @Test("Tool Use encoding/decoding - basic command")
    func test_toolUseEncodingDecodingBasic() throws {
      let tool = ExecuteCommandTool()
      let input = ExecuteCommandTool.Use.Input(
        command: "pwd",
        cwd: nil,
        canModifySourceFiles: false,
        canModifyDerivedFiles: false)
      let use = tool.use(toolUseId: "exec-123", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(ExecuteCommandTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "exec-123")
      #expect(decodedUse.input.command == "pwd")
      #expect(decodedUse.input.cwd == nil)
      #expect(decodedUse.input.canModifySourceFiles == false)
      #expect(decodedUse.input.canModifyDerivedFiles == false)
    }

    @Test("Tool Use encoding/decoding - with all options")
    func test_toolUseEncodingDecodingComplete() throws {
      let tool = ExecuteCommandTool()
      let input = ExecuteCommandTool.Use.Input(
        command: "npm test",
        cwd: "/frontend",
        canModifySourceFiles: true,
        canModifyDerivedFiles: true)
      let use = tool.use(toolUseId: "exec-npm-456", input: input, context: toolExecutionContext)

      // Test encoding/decoding round trip
      let encodedData = try JSONEncoder().encode(use)
      let decodedUse = try JSONDecoderWithTool().decode(ExecuteCommandTool.Use.self, from: encodedData)

      #expect(decodedUse.toolUseId == "exec-npm-456")
      #expect(decodedUse.input.command == "npm test")
      #expect(decodedUse.input.cwd == "/frontend")
      #expect(decodedUse.input.canModifySourceFiles == true)
      #expect(decodedUse.input.canModifyDerivedFiles == true)
    }

    @Test("Tool Use encoding produces expected JSON structure")
    func test_toolUseEncodingStructure() throws {
      let tool = ExecuteCommandTool()
      let input = ExecuteCommandTool.Use.Input(
        command: "make clean && make build",
        cwd: "/build",
        canModifySourceFiles: false,
        canModifyDerivedFiles: true)
      let use = tool.use(toolUseId: "exec-make-789", input: input, context: toolExecutionContext)

      let encodedData = try JSONEncoder().encode(use)

      // Validate the structure while ignoring dynamic fields
      encodedData.expectToMatch("""
        {
          "callingTool": "execute_command",
          "input": {
            "canModifyDerivedFiles": true,
            "canModifySourceFiles": false,
            "command": "make clean && make build",
            "cwd": "/build"
          },
          "status": {
            "status": "notStarted"
          },
          "toolUseId": "exec-make-789"
        }
        """)
    }
  }
}

/// Create a JSON decoder that has context about the relevant tool.
private func JSONDecoderWithTool() -> JSONDecoder {
  let tool = ExecuteCommandTool()
  let toolsPlugin = ToolsPlugin()
  toolsPlugin.plugIn(tool: tool)

  let decoder = JSONDecoder()
  decoder.userInfo.set(toolPlugin: toolsPlugin)

  return decoder
}

private let toolExecutionContext = ToolExecutionContext(
  project: nil,
  projectRoot: nil)
