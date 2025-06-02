// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - ThreeDotsLoadingAnimation

public struct ThreeDotsLoadingAnimation: View {
  public init(duration: TimeInterval = 2) {
    self.duration = duration
  }

  public var body: some View {
    HStack {
      Text(text)
        .onAppear {
          startAnimation()
        }
    }
  }

  @State private var i = 0

  private let duration: TimeInterval

  private var text: String {
    String(repeating: ".", count: i) + String(repeating: " ", count: 4 - i)
  }

  private func startAnimation() {
    let stepDuration = duration / 4 // 4 steps: "", ".", "..", "..."

    Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { _ in
      Task { @MainActor in
        withAnimation(.easeInOut(duration: stepDuration * 0.3)) {
          i = (i + 1) % 4
        }
      }
    }
  }
}

#if DEBUG
#Preview {
  ThreeDotsLoadingAnimation(duration: 2)
}
#endif
