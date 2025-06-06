// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

#if DEBUG

#Preview("Internal Settings - Component Only") {
  InternalSettingsView(
    repeatLastLLMInteraction: .constant(true),
    showOnboardingScreenAgain: .constant(true),
    pointReleaseXcodeExtensionToDebugApp: .constant(false),
    showInternalSettingsInRelease: .constant(false),
    defaultChatPositionIsInverted: .constant(false))
    .frame(width: 600, height: 400)
    .padding()
}

#Preview("Internal Settings - Debug Enabled") {
  InternalSettingsView(
    repeatLastLLMInteraction: .constant(false),
    showOnboardingScreenAgain: .constant(true),
    pointReleaseXcodeExtensionToDebugApp: .constant(true),
    showInternalSettingsInRelease: .constant(true),
    defaultChatPositionIsInverted: .constant(true))
    .frame(width: 600, height: 400)
    .padding()
}

#endif
