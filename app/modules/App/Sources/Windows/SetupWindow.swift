// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Onboarding
import SwiftUI

final class SetupWindow: NSWindow {

  init() {
    // Use a temporary size that will be adjusted once content is loaded
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
      styleMask: [.closable, .miniaturizable, .resizable, .titled],
      backing: .buffered,
      defer: false)

    let root = SetupView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)

    let hostingView = NSHostingView(rootView: root)

    hostingView.translatesAutoresizingMaskIntoConstraints = false
    contentView = hostingView

    if let contentView {
      NSLayoutConstraint.activate([
        hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
        hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])
    }

    // Size window to fit content
    setContentSize(hostingView.fittingSize)

    // Center window on screen
    center()
  }
}
