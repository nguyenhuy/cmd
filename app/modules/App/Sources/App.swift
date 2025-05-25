// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
@preconcurrency import Darwin
import Dependencies
import ExtensionCommandHandler
import Foundation
import LoggingServiceInterface
import SwiftUI
import XcodeObserverServiceInterface

var machTaskSelf: mach_port_t {
  mach_task_self_
}

// MARK: - XcompanionApp

public struct XcompanionApp: App {

  public init() {
    let isAppActive = _appDelegate.wrappedValue.isAppActive.removeDuplicates().eraseToAnyPublisher()
    self.isAppActive = isAppActive
    AppScope.shared.create(isAppActive: isAppActive)

    let windowsViewModel = WindowsViewModel()
    self.windowsViewModel = windowsViewModel
    windows = WindowsView(viewModel: windowsViewModel)
    // TODO: move somewhere else.
    extensionCommandHandler = ExtensionCommandHandler()

    // Post init actions
    appDelegate.handleApplicationShouldHandleReopen = {
      windowsViewModel.handle(.showApplication)
    }
    appDelegate.handleApplicationDidBecomeActive = {
      windowsViewModel.handle(.showApplication)
    }
    xcodeKeyboardShortcutsManager = XcodeKeyboardShortcutsManager(appsActivationState: appsActivationState)
    registerColdStartPlugins()
    Task {
      // Initialize the local server on launch
      @Dependency(\.server) var server
      _ = try? await server.getRequest(path: "launch")
    }

    #if DEBUG
    timer = Timer(timeInterval: 1, repeats: true, block: { _ in
      Task { @MainActor in
        Self.report_memory()
      }
    })
    RunLoop.main.add(timer!, forMode: .common)
    #endif
  }

  public var body: some Scene {
    MenuBarExtra {
      Button("Settings…") { print("settings") }
        .keyboardShortcut(",", modifiers: .command)
      Divider()
      Button("Quit") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q")
    } label: {
      #if DEBUG
      Text("??")
      #else
      Text("?")
      #endif
    }.commands {
      CommandGroup(before: .appSettings) {
        Button("Settings…") {
          print("settings")
        }
        .keyboardShortcut(",", modifiers: .command)
      }
    }
  }

  let isAppActive: AnyPublisher<Bool, Never>

  #if DEBUG
  @MainActor
  static func report_memory() {
    var info = mach_task_basic_info()
    let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
    var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      if info.resident_size > 1000000000 {
        defaultLogger.error("Memory in use (in bytes): \(info.resident_size / 1000000000) GB")
      }
    } else {
      defaultLogger.error(
        "Error with task_info(): " +
          (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
    }
  }

  private var timer: Timer?
  #endif

  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  private let extensionCommandHandler: ExtensionCommandHandler

  private let windowsViewModel: WindowsViewModel
  private let windows: WindowsView

  @Dependency(\.appsActivationState) private var appsActivationState

  private var xcodeKeyboardShortcutsManager: XcodeKeyboardShortcutsManager?

  private func registerColdStartPlugins() {
    AppScope.shared.toolsPlugin.registerToolsPlugin()
  }

}

// MARK: - AppDelegate

private final class AppDelegate: NSObject, NSApplicationDelegate {
  let isAppActive = CurrentValueSubject<Bool, Never>(false)

  var handleApplicationShouldHandleReopen: (() -> Void)?

  var handleApplicationDidBecomeActive: (() -> Void)?

  func applicationDidBecomeActive(_: Notification) {
    isAppActive.send(true)
    handleApplicationDidBecomeActive?()
  }

  func applicationDidResignActive(_: Notification) {
    isAppActive.send(false)
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    handleApplicationShouldHandleReopen?()
    return true
  }
}
