// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import DLS
import SwiftUI

// MARK: - OnboardingCompletedView

struct OnboardingCompletedView: View {
  let onDone: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text("Setup Complete!")
        .font(.title)
        .bold()

      Text("In Xcode, you can now use:\n- **⌘ + I** to use the agent mode\n- **⌘ + L** to use the chat mode.")
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: OnboardingView.Constants.maxTextWidth, alignment: .leading)

      HoveredButton(
        action: {
          onDone()
        },
        onHoverColor: .accentColor.opacity(0.8),
        backgroundColor: .accentColor,
        padding: 16,
        cornerRadius: 12)
      {
        Text("Start using **cmd**")
      }
      Spacer(minLength: 0)
    }
    .padding()
  }

  @Environment(\.colorScheme) private var colorScheme
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
  OnboardingCompletedView(onDone: { })
    .padding()
}
#endif
