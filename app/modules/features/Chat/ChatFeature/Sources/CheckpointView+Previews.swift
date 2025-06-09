// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
