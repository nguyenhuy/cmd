// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DLS
import PermissionsServiceInterface
import SwiftUI

// TODO: if no API provider is setup, show a message to the user to get the keys.
public struct SetupView: View {
  public init() { }

  @Dependency(\.permissionsService) private var permissionsService

  public var body: some View {
    // Example usage
    VStack {
      Text("command needs accessibility permissions to interact with Xcode.").padding()
      PlainButton(title: "Give permissions") {
        permissionsService.request(permission: .accessibility)
      }
    }
    .padding()
    .background(colorScheme.primaryBackground)
  }

  @Environment(\.colorScheme) private var colorScheme
}

#Preview("SetupView") {
  SetupView()
}
