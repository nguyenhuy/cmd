// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import CheckpointServiceInterface
import SwiftUI

#if DEBUG
struct CheckpointView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 10) {
      CheckpointView(
        checkpoint: Checkpoint(id: "1", message: "Initial Checkpoint", projectRoot: URL(filePath: ""), taskId: "1"))

      CheckpointView(
        checkpoint: Checkpoint(id: "1", message: "Initial Checkpoint", projectRoot: URL(filePath: ""), taskId: "1"))
    }
    .padding()
    .previewLayout(.sizeThatFits)
    .preferredColorScheme(.dark)

    VStack(spacing: 10) {
      CheckpointView(
        checkpoint: Checkpoint(id: "1", message: "Initial Checkpoint", projectRoot: URL(filePath: ""), taskId: "1"))

      CheckpointView(
        checkpoint: Checkpoint(id: "1", message: "Initial Checkpoint", projectRoot: URL(filePath: ""), taskId: "1"))
    }
    .padding()
    .previewLayout(.sizeThatFits)
    .preferredColorScheme(.light)
  }
}
#endif
