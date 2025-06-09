// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

struct PermissionsView: View {

  let viewModel: OnboardingViewModel

  var body: some View {
    VStack {
      Text("1/2 - Permissions")
        .font(.headline)
        .padding(.bottom, 8)

      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          AccessibilityPermissionView(
            isAccessibilityPermissionGranted: viewModel.isAccessibilityPermissionGranted,
            requestAccessibilityPermission: viewModel.handleRequestAccessibilityPermission)

          if viewModel.isAccessibilityPermissionGranted {
            XcodeExtensionPermissionView(
              isXcodeExtensionPermissionGranted: viewModel.isXcodeExtensionPermissionGranted,
              skipXcodeExtensionPermissions: {
                viewModel.handleMoveToNextStep()
              }, requestXcodeExtensionPermission: viewModel.handleRequestXcodeExtensionPermission)
          }
          Spacer(minLength: 0)
        }
        Spacer(minLength: 0)
      }
    }
  }

}
