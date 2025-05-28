// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

#if DEBUG

#Preview("About Settings - Analytics Enabled") {
  AboutSettingsView(allowAnonymousAnalytics: .constant(true))
    .frame(width: 600, height: 400)
    .padding()
}

#Preview("About Settings - Analytics Disabled") {
  AboutSettingsView(allowAnonymousAnalytics: .constant(false))
    .frame(width: 600, height: 400)
    .padding()
}

#endif
