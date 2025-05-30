// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

#if DEBUG

#Preview("Internal Settings - Component Only") {
  InternalSettingsView(
    pointReleaseXcodeExtensionToDebugApp: .constant(false),
    allowAnonymousAnalytics: .constant(true))
    .frame(width: 600, height: 400)
    .padding()
}

#Preview("Internal Settings - Debug Enabled") {
  InternalSettingsView(
    pointReleaseXcodeExtensionToDebugApp: .constant(true),
    allowAnonymousAnalytics: .constant(false))
    .frame(width: 600, height: 400)
    .padding()
}

#endif
