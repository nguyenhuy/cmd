// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DLS
import PermissionsServiceInterface
import SwiftUI

// TODO: if no API provider is setup, show a message to the user to get the keys.
struct SetupView: View {
  @Dependency(\.permissionsService) private var permissionsService

  var body: some View {
    // Example usage
    VStack {
      Text("Xcompanion needs accessibility permissions to interact with Xcode.").padding()
      PlainButton(title: "Give permissions") {
        permissionsService.request(permission: .accessibility)
      }
    }
    .padding()
  }
}

#Preview("SetupView") {
  SetupView()
}
