// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import SwiftUI
import XcodeControllerServiceInterface

#if DEBUG
#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .test,
        status: .Just(.running)))
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .run,
        status: .Just(.notStarted)))
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .run,
        status: .Just(.completed(.success(.init(
          buildResult: BuildSection(
            title: "Build Target",
            messages: [
              .init(message: "Careful with that", severity: .warning, location: nil),
              .init(message: "Build succeeded", severity: .info, location: nil),
            ],
            subSections: [],
            duration: 2.5),
          isSuccess: true))))))
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .run,
        status: .Just(.completed(.success(.init(
          buildResult: BuildSection(
            title: "Build Target",
            messages: [
              .init(message: "Oupsy", severity: .error, location: .init(
                file: URL(fileURLWithPath: "/path/to/file.swift"),
                startingLineNumber: 1,
                startingColumnNumber: 1,
                endingLineNumber: 1,
                endingColumnNumber: 14)),
              .init(message: "Careful with that", severity: .warning, location: nil),
              .init(message: "Build failed", severity: .info, location: nil),
            ],
            subSections: [],
            duration: 1.2),
          isSuccess: false))))))
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .run,
        status: .Just(.completed(.failure(AppError("Failed to build"))))))
    }
  }
  .frame(minWidth: 200, minHeight: 500)
  .padding()
}
#endif
