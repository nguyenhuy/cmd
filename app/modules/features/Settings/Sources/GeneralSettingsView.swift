// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

struct GeneralSettingsView: View {
  @Binding var pointReleaseXcodeExtensionToDebugApp: Bool

  var body: some View {
    VStack(spacing: 0) {
      #if DEBUG
      HStack {
        Text("Point Release Xcode Extension to Debug App")
        Spacer()
        Toggle("", isOn: $pointReleaseXcodeExtensionToDebugApp)
          .toggleStyle(.switch)
      }

      #endif
    }
  }
}
