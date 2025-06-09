// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AskFollowUpTool
import BuildTool
import EditFilesTool
import ExecuteCommandTool
import LSTool
import ReadFileTool
import SearchFilesTool
import ToolFoundation

extension ToolsPlugin {
  func registerToolsPlugin() {
    plugIn(tool: LSTool())
    plugIn(tool: ReadFileTool())
    plugIn(tool: SearchFilesTool())
    plugIn(tool: EditFilesTool(shouldAutoApply: true))
    // plugIn(tool: EditFilesTool(shouldAutoApply: false))
    plugIn(tool: ExecuteCommandTool())
    plugIn(tool: AskFollowUpTool())
    plugIn(tool: BuildTool())
  }
}
