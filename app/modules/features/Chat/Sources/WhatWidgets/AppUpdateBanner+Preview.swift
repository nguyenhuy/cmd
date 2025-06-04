// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import SwiftUI

#if DEBUG
private let appUpdateInfo = AppUpdateInfo(
  version: "1.0.0",
  fileURL: nil,
  releaseNotesURL: URL(string: "https://example.com/release-notes")!)
#Preview("AppUpdateBanner", traits: .sizeThatFitsLayout) {
  AppUpdateBanner(
    appUpdateInfo: appUpdateInfo,
    onRelaunchTapped: { },
    onSkipTapped: { })
}
#endif
