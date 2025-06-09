// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - PlainButton

public struct PlainButton: View {

  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      Text(title)
        .foregroundColor(.primary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .tappableTransparentBackground()
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue))
    }
    .buttonStyle(.plain)
    .acceptClickThrough()
  }

  let title: String
  let action: () -> Void

}

#Preview("PlainButton") {
  PlainButton(title: "Preview Button") {
    print("Preview button tapped")
  }
}

extension Color {
  public static let tappableClearButton = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.0001)
}
