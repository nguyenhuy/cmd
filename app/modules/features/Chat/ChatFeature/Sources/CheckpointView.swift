// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import CheckpointServiceInterface
import SwiftUI

// MARK: - CheckpointView

/// A view that displays a checkpoint in the chat history.
struct CheckpointView: View {

  init(checkpoint: Checkpoint, onRestoreTapped: ((Checkpoint) -> Void)? = nil) {
    self.checkpoint = checkpoint
    self.onRestoreTapped = onRestoreTapped
  }

  let checkpoint: Checkpoint
  let onRestoreTapped: ((Checkpoint) -> Void)?

  var body: some View {
    HStack(spacing: 8) {
      CircleWithLine(circleRadiusRatio: 0.25, lineWidthRatio: 0.15)
        .fill(Color.blue)
        .frame(width: 20, height: 20)
        .scaledToFit()

      Text("Checkpoint")
        .fontWeight(.medium)
        .foregroundColor(.primary)

      Spacer()

      Button(action: {
        onRestoreTapped?(checkpoint)
      }) {
        Text("Restore")
          .foregroundColor(Color.gray)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(ChatMessageView.Constants.checkpointPadding)
  }
}

// MARK: - CircleWithLine

/// A line with a circle at the center, the icon for the checkpoint.
struct CircleWithLine: Shape {
  var circleRadiusRatio: CGFloat
  var lineWidthRatio: CGFloat

  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height

    let circleRadius = min(width, height) * circleRadiusRatio
    let lineWidth = width * lineWidthRatio
    let centerX = rect.midX
    let centerY = rect.midY

    var path = Path()

    path.addRect(CGRect(
      x: centerX - lineWidth / 2,
      y: rect.minY,
      width: lineWidth,
      height: height))

    path.addEllipse(in: CGRect(
      x: centerX - circleRadius,
      y: centerY - circleRadius,
      width: 2 * circleRadius,
      height: 2 * circleRadius))

    return path
  }
}
