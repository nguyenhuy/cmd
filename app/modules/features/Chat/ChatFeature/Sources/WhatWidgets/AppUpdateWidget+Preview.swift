// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import AppUpdateServiceInterface
import SwiftUI

#if DEBUG
private let appUpdateInfo = AppUpdateInfo(
  version: "1.0.0",
  fileURL: nil,
  releaseNotesURL: URL(string: "https://example.com/release-notes")!)
#Preview("AppUpdateWidget", traits: .sizeThatFitsLayout) {
  VisibleAppUpdateWidget(
    appUpdateInfo: appUpdateInfo,
    onRelaunchTapped: { },
    onIgnoreTapped: { })
}
#endif
