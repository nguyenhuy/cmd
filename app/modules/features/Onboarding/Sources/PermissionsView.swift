// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
