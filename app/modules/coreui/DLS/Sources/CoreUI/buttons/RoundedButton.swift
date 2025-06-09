// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

public struct RoundedButton<Label: View>: View {

  public init(
    padding: EdgeInsets = .init(top: 3, leading: 3, bottom: 3, trailing: 3),
    cornerRadius: CGFloat = 6,
    action: @escaping () -> Void,
    label: @escaping () -> Label)
  {
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.action = action
    self.label = label
  }

  public var body: some View {
    Button(action: action) {
      label()
        .padding(padding)
        .tappableTransparentBackground()
    }
    .buttonStyle(PlainButtonStyle())
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(Color.gray.opacity(0.4), lineWidth: 1))
    .acceptClickThrough()
  }

  let padding: EdgeInsets
  let cornerRadius: CGFloat
  let action: () -> Void
  let label: () -> Label

}

#Preview("PlainButton") {
  VStack {
    RoundedButton(action: {
      print("Preview button tapped")
    }) {
      Text("Give permissions")
    }
  }.padding()
}
