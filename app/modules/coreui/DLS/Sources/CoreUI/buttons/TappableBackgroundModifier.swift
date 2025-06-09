// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - TappableBackgroundModifier

/// A view modifier that adds a transparent background to make the entire view tappable
struct TappableBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      // This is necessary to make the transparent background clickable...
      .background(Color.gray.opacity(0.001))
  }
}

extension View {
  /// Adds a nearly invisible background to ensure the entire view is tappable
  /// - Returns: A view with a transparent background that makes it fully tappable
  public func tappableTransparentBackground() -> some View {
    modifier(TappableBackgroundModifier())
  }
}

#Preview {
  VStack {
    Text("Tap me")
      .padding()
      .tappableTransparentBackground()
      .border(Color.red)
      .onTapGesture {
        print("Tapped!")
      }
  }
}
