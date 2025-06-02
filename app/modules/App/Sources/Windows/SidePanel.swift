// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
import AccessibilityObjCFoundation
import AppKit
import AppUpdater
import Chat
import Dependencies
import LoggingServiceInterface
import SettingsFeature
import SwiftUI
import XcodeObserverServiceInterface

/// A side panel displayed on the side of Xcode.
final class SidePanel: XcodeWindow {

  init(windowsViewModel: WindowsViewModel) {
    self.windowsViewModel = windowsViewModel

    super.init(contentRect: .zero)

    styleMask = [.closable, .miniaturizable, .resizable, .titled]
    hasShadow = false

    // Configure title bar with solid background and fixed height
    titlebarAppearsTransparent = false
    titleVisibility = .hidden

    // Create and configure toolbar for fixed height
    let toolbar = NSToolbar(identifier: "SidePanelToolbar")
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.autosavesConfiguration = false
    self.toolbar = toolbar

    // Set fixed title bar height, same as Xcode's.
    if let titlebarContainer = standardWindowButton(.closeButton)?.superview?.superview {
      titlebarContainer.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    collectionBehavior = [
      .fullScreenAuxiliary,
      .fullScreenPrimary,
      .fullScreenAllowsTiling,
    ]

    let idealFrame = trackedWindow.map { self.frame(from: $0) } ?? nil
    let defaultFrame = CGRect.zero

    let frame = idealFrame ?? defaultFrame
    if trackedWindow != nil {
      setFrame(frame, display: isVisible)
      makeKeyAndOrderFront(nil)
    }
    lastWindowFrame = frame

    backgroundColor = .clear

    let root = ChatView(
      viewModel: ChatViewModel(),
      SettingsView: { onDismiss in
        AnyView(SettingsView(
          viewModel: SettingsViewModel(),
          onDismiss: onDismiss))
      },
      AppUpdaterView: { _ in
        AppUpdaterBuilder.build()
      })
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
  }

  override var canBecomeKey: Bool { true }

  override var acceptsFirstResponder: Bool { true }

  var defaultWidth: CGFloat { 400 }

  override func getFrame() -> CGRect? {
    guard let trackedWindow else { return nil }
    let frame = frame(from: trackedWindow)
    if frame == .zero {
      windowsViewModel.handle(.stopChat)
    }
    if let frame {
      lastWindowFrame = frame
    }
    return frame
  }

  override func close() {
    windowsViewModel.handle(.closeSidePanel)
  }

  override func hide() {
    lastWorkspaceFrame = nil
    lastWorkspaceElement = nil
    combinedFrame = nil
    defer { super.hide() }

    // Ensures Xcode has focus.
    if
      let xcodeApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode").last,
      let trackedWindow = trackedWindow?.wrappedValue
    {
      WindowActivation.activateAppAndMakeWindowFront(xcodeApp, window: trackedWindow)
    }

    // Expand Xcode to take the space of the host app.
    guard
      let trackedWindow,
      let workspaceFrame = trackedWindow.appKitFrame
    else { return }

    var xcodeFrame = CGRect(
      origin: workspaceFrame.origin,
      size: CGSize(width: frame.maxX - workspaceFrame.minX, height: workspaceFrame.height))
    // Make sure we're not extending beyond the screen, which could happen if the host app was off screen or on another screen.
    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(workspaceFrame.origin) }) else {
      return
    }
    xcodeFrame = screen.frame.intersection(xcodeFrame)
    guard xcodeFrame.intersection(workspaceFrame) == workspaceFrame else {
      // modifying the frame would reduce the current frame. Abort.
      return
    }
    trackedWindow.set(appKitframe: xcodeFrame)
  }

  private var lastWorkspaceFrame: CGRect?
  private var lastWorkspaceElement: AnyAXUIElement?
  private var lastWindowFrame: CGRect?

  private var combinedFrame: CGRect?

  private let windowsViewModel: WindowsViewModel

  @MainActor
  private func frame(from window: AnyAXUIElement) -> CGRect? {
    // TODO: gracefully handle when the screen changes
    // TODO: make the experience moving the window nicer.
    // TODO: prevent the combine frame from extending beyond the screen.
    let hostAppFrame = frame
    guard let workspaceFrame = window.appKitFrame else {
      // This can happen when there is no screen. For instance the laptop was closed.
      return nil
    }
    defer {
      lastWorkspaceFrame = workspaceFrame
      lastWorkspaceElement = window
    }

//    if
//      let lastWorkspaceFrame,
//      let lastWorkspaceElement,
//      let lastWindowFrame,
//      lastWorkspaceElement == window
//    {
//      if workspaceFrame.size != lastWorkspaceFrame.size {
//        // Xcode workspace was resized. Also resize the chat window.
//        return CGRect(
//          origin: CGPoint(
//            x: workspaceFrame.maxX,
//            y: workspaceFrame.minY),
//          size: CGSize(
//            width: lastWindowFrame.maxX - workspaceFrame.maxX,
//            height: workspaceFrame.height))
//      } else if workspaceFrame != lastWorkspaceFrame {
//        // Xcode workspace moved. Also move the chat window.
//        return CGRect(
//          origin: CGPoint(
//            x: workspaceFrame.maxX,
//            y: workspaceFrame.minY),
//          size: lastWindowFrame.size)
//      }
//    }

    let combinedFrame = workspaceFrame.union(hostAppFrame)
    if self.combinedFrame == nil {
      self.combinedFrame = combinedFrame

      let screen = NSScreen.screens.first(where: { $0.frame.contains(workspaceFrame.origin) })?.frame
      let frame = CGRect(
        origin: CGPoint(
          // Make sure the frame is within the screen bounds.
          x: min(workspaceFrame.maxX, (screen?.maxX ?? .infinity) - defaultWidth),
          y: workspaceFrame.minY),
        size: CGSize(width: defaultWidth, height: workspaceFrame.height))

      let xcodeFrame = CGRect(
        origin: workspaceFrame.origin,
        size: CGSize(
          width: frame.minX - workspaceFrame.minX,
          height: combinedFrame.height))
      window.set(appKitframe: xcodeFrame)

      return frame
    }
    return nil
  }

}
