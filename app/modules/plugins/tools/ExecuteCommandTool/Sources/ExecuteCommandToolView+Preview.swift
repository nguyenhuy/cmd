// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import SwiftUI
import ToolFoundation

#if DEBUG
extension ToolUseViewModel {
  convenience init(
    command: String,
    status: ExecuteCommandTool.Use.Status)
  {
    self.init(
      command: command,
      status: status,
      stdout: .Just(.Just(Data())),
      stderr: .Just(.Just(Data())),
      kill: { try? await Task.sleep(for: .seconds(1)) })
  }
}

#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      ToolUseView(toolUse: ToolUseViewModel(
        command: "ls",
        status: .Just(.running)))
      ToolUseView(toolUse: ToolUseViewModel(
        command: "ls",
        status: .Just(.notStarted)))
      ToolUseView(toolUse: ToolUseViewModel(
        command: "ls",
        status: .Just(.completed(.success(.init(
          output: "filePath",
          exitCode: 0)))),
        stdout: .Just(.Just(String("""
          total 0
          drwxr-xr-x@ 6 me  staff   192B Mar 26 21:41 ./
          drwxr-xr-x@ 4 me  staff   128B Mar 21 09:38 ../
          drwxr-xr-x@ 8 me  staff   256B Mar 27 15:01 ExecuteCommandTool/
          drwxr-xr-x@ 7 me  staff   224B Mar 27 15:01 LSTool/
          drwxr-xr-x@ 7 me  staff   224B Mar 27 15:01 ReadFileTool/
          drwxr-xr-x@ 7 me  staff   224B Mar 27 15:01 SearchFilesTool/
          """).utf8Data)),
        stderr: .Just(.Just(Data())),
        kill: { }))
    }
  }
  .frame(minWidth: 200, minHeight: 500)
  .padding()
}
#endif
