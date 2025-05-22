// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import SwiftUI

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
        status: .Just(.completed(.success(.init())))))
      ToolUseView(toolUse: ToolUseViewModel(
        buildType: .run,
        status: .Just(.completed(.failure(AppError("Failed to build"))))))
    }
  }
  .frame(minWidth: 200, minHeight: 500)
  .padding()
}
#endif
