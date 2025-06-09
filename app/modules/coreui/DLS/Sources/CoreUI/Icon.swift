// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

public struct Icon: View {

  public init(systemName: String) {
    self.systemName = systemName
  }

  public var body: some View {
    Image(systemName: hasTapped ? "checkmark" : systemName)
      .resizable()
      .interpolation(.none)
      .scaledToFit()
  }

  let systemName: String

  @State private var hasTapped = false
}

#Preview {
  VStack {
    Image(systemName: "doc.on.doc")
      .frame(width: 10, height: 10)
      .border(.blue)
    Image(systemName: "doc.on.doc")
      .frame(width: 20, height: 20)
      .border(.blue)
    Image(systemName: "doc.on.doc")
      .frame(width: 10, height: 20)
      .border(.blue)
  }
  .padding()
}
