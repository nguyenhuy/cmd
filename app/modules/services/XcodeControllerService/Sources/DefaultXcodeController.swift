// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventServiceInterface
import AppFoundation
import AppKit
import ConcurrencyFoundation
import DependencyFoundation
import ExtensionEventsInterface
import FileDiffFoundation
import FoundationInterfaces
import LoggingServiceInterface
import SettingsServiceInterface
import SharedValuesFoundation
import ShellServiceInterface
import ThreadSafe
import XcodeControllerServiceInterface
import XcodeObserverServiceInterface

// MARK: - DefaultXcodeController

@ThreadSafe
public final class DefaultXcodeController: XcodeController, Sendable {

  public convenience init(
    appEventHandlerRegistry: AppEventHandlerRegistry,
    shellService: ShellService,
    xcodeObserver: XcodeObserver,
    settingsService: SettingsService,
    fileManager: FileManagerI)
  {
    self.init(
      appEventHandlerRegistry: appEventHandlerRegistry,
      shellService: shellService,
      xcodeObserver: xcodeObserver,
      settingsService: settingsService,
      fileManager: fileManager,
      timeout: ExtensionTimeout.applyFileChangeTimeout,
      canUseAppleScript: true,
      startApplyingFileChange: { Task { @MainActor in
        try await Self.triggerExtension(
          xcodeObserver: xcodeObserver,
          shellService: shellService,
          settingsService: settingsService)
      }})
  }

  public init(
    appEventHandlerRegistry: AppEventHandlerRegistry,
    shellService: ShellService,
    xcodeObserver: XcodeObserver,
    settingsService: SettingsService,
    fileManager: FileManagerI,
    timeout: TimeInterval,
    canUseAppleScript: Bool = false,
    startApplyingFileChange: @escaping @Sendable () async throws -> Void)
  {
    self.appEventHandlerRegistry = appEventHandlerRegistry
    self.shellService = shellService
    self.xcodeObserver = xcodeObserver
    self.settingsService = settingsService
    self.fileManager = fileManager
    self.startApplyingFileChange = startApplyingFileChange
    self.timeout = timeout
    self.canUseAppleScript = canUseAppleScript

    registerAppEventHandler()
  }

  /// Apply the file change using the Xcode extension.
  /// If other changes are pending, this will wait for them to complete first.
  public func apply(fileChange: FileChange) async throws {
    try await tasksQueue.queueAndAwait { [weak self] in
      try await self?._apply(fileChange: fileChange)
    }
  }

  /// Open a file in Xcode at the specified line and column.
  public func open(file: URL, line _: Int?, column _: Int?) async throws {
    Task {
      do {
        try await Self.openFileWithAppleScript(at: file)
      } catch {
        defaultLogger.error("Failed to open file with AppleScript", error)
      }
    }
  }

  let shellService: ShellService
  let xcodeObserver: XcodeObserver
  let fileManager: FileManagerI

  #if DEBUG
  var currentExecutionId: String? {
    fileChange?.id
  }
  #endif

  private let tasksQueue = TaskQueue<Void, any Error>()
  private var fileChange: FileChange?
  private var currentContinuation: CheckedContinuation<Void, Error>?

  // Configuration variable that can be changed for testing.
  private let timeout: TimeInterval
  private let canUseAppleScript: Bool

  private let appEventHandlerRegistry: AppEventHandlerRegistry
  private let settingsService: SettingsService

  /// Start applying the code change, typically by selecting the extension menu item in Xcode.
  private let startApplyingFileChange: @Sendable () async throws -> Void

  private func registerAppEventHandler() {
    appEventHandlerRegistry.registerHandler { [weak self] event in
      guard let self else {
        return false
      }
      switch event {
      case let event as ExecuteExtensionRequestEvent:
        if
          event.command == ExtensionCommandKeys.getFileChangeToApply || event.command == ExtensionCommandKeys
            .confirmFileChangeApplied
        {
          do {
            if event.command == ExtensionCommandKeys.getFileChangeToApply {
              let fileChange = try getFileChangeToApply()
              event.completion(.success(fileChange))
            } else {
              let result = try JSONDecoder().decode(ExtensionRequest<FileChangeConfirmation>.self, from: event.data)
              fileChangeApplied(withError: result.input.error)
              event.completion(.success(EmptyResponse()))
            }
          } catch {
            defaultLogger.error("Failed to handle extension request '\(event.command)': \(error)")
            fileChangeApplied(withError: error.localizedDescription)
            event.completion(.failure(error))
          }
          return true
        }
        return false

      default:
        return false
      }
    }
  }

  /// Apply the file change using the Xcode extension, assuming none are pending.
  private func _apply(fileChange: FileChange) async throws {
    do {
      guard fileManager.fileExists(atPath: fileChange.filePath.path) else {
        let data = fileChange.suggestedNewContent.utf8Data
        // TODO: look at making the required modification to the xcode project if necessary.
        try fileManager.write(data: data, to: fileChange.filePath)
        return
      }
      try await applyWithXcodeExtension(fileChange: fileChange)
    } catch {
      let err = error
      defaultLogger.error("Failed to apply code change with Xcode extension, falling back to Apple Script: \(err)")
      do {
        guard canUseAppleScript else {
          throw err
        }
        try await Self.modifyFile(at: fileChange.filePath, with: fileChange.suggestedNewContent)
      } catch {
        // Rethrow the original error if the fallback fails.
        throw err
      }
    }
  }

  private func applyWithXcodeExtension(fileChange: FileChange) async throws {
    let start = Date()
    let timeout = timeout

    return try await withCheckedThrowingContinuation { continuation in
      Task {
        inLock { state in
          state.fileChange = fileChange
          state.currentContinuation = continuation
        }

        do {
          if xcodeObserver.state.focusedWorkspace?.url != fileChange.filePath, canUseAppleScript {
            defaultLogger
              .log(
                "Opening file '\(fileChange.filePath)' in Xcode. Current file: \(xcodeObserver.state.focusedWorkspace?.url.path() ?? "nil")")
            try? await Self.openFileWithAppleScript(at: fileChange.filePath)
          }

          try await startApplyingFileChange()
          let duration = Date().timeIntervalSince(start)
          defaultLogger.log("Time to trigger extension: \(duration)")
        } catch {
          defaultLogger.error("triggerExtension failed: \(error)")
          let currentContinuation = inLock { state in
            let currentContinuation = state.currentContinuation
            state.currentContinuation = nil
            state.fileChange = nil
            return currentContinuation
          }
          currentContinuation?.resume(throwing: error)
        }
      }

      Task { [weak self] in
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        self?.timeOut(fileChange: fileChange)
      }
    }
  }

  private func getFileChangeToApply() throws -> FileChange {
    guard let fileChange else {
      throw AppError(message: "No code change to apply")
    }
    return fileChange
  }

  private func timeOut(fileChange: FileChange) {
    let currentContinuation: CheckedContinuation<Void, Error>? = inLock { state in
      guard state.fileChange?.id == fileChange.id, let currentContinuation = state.currentContinuation else {
        return nil
      }
      state.currentContinuation = nil
      state.fileChange = nil
      return currentContinuation
    }

    if let currentContinuation {
      currentContinuation.resume(throwing: AppError(message: "Apply suggestion timed out"))
      defaultLogger.error("Extension timed-out while applying the edit.")
    }
  }

}

// MARK: - MenuSelector

extension DefaultXcodeController {

  @MainActor
  static func triggerExtension(
    xcodeObserver: XcodeObserver,
    shellService: ShellService,
    settingsService: SettingsService)
    async throws
  {
    guard let xcodeApp = await getXcode(xcodeObserver: xcodeObserver, shellService: shellService) else {
      defaultLogger.error("Could not find running Xcode")
      throw AXError.cannotComplete
    }

    if !xcodeApp.activate() {
      defaultLogger.error("Xcode not activated.")
      try? activateXcodeWithAppleScript()
    }

    let appElement = AXUIElementCreateApplication(xcodeApp.processIdentifier)

    guard let menuBar = appElement.menuBar else {
      defaultLogger.error("Could not find menu bar")
      throw AXError.cannotComplete
    }

    #if DEBUG
    let appBundleId = settingsService.value(for: \.pointReleaseXcodeExtensionToDebugApp)
      ? Bundle.main.releaseHostAppBundleId
      : Bundle.main.hostAppBundleId
    #else
    let appBundleId = Bundle.main.hostAppBundleId
    #endif
    guard
      let menuItem = menuBar
        .firstChild(where: { $0.title == ExtensionCommandNames.applyEdit && $0.identifier?.contains(appBundleId) == true })
    else {
      defaultLogger.error("Could not find '\(appBundleId):\(ExtensionCommandNames.applyEdit)' menu")
      throw AXError.cannotComplete
    }

    if AXUIElementPerformAction(menuItem, kAXPressAction as CFString) == .success {
      defaultLogger.log("Clicked the menu item")
    } else {
      defaultLogger.error("Failed to click menu item.")
      throw AXError.cannotComplete
    }

    NSApplication.shared.activate()
  }

  @MainActor
  static func getXcode(xcodeObserver: XcodeObserver, shellService: ShellService) async -> NSRunningApplication? {
    #if DEBUG
    // When in DEBUG mode, we first check if there is an instance of Xcode that has been launched by attaching to the extension.
    for pid in xcodeObserver.state.wrapped?.xcodesState.map(\.processIdentifier) ?? [] {
      if await shellService.isXcodeInstanceUsedByDebugExtension(processIdentifier: pid) {
        if let app = NSRunningApplication(processIdentifier: pid) {
          return app
        }
      }
    }
    #endif
    if
      let processId = xcodeObserver.state.wrapped?.xcodesState.first?.processIdentifier,
      let app = NSRunningApplication(processIdentifier: processId)
    {
      return app
    }
    defaultLogger.error("Could not find Xcode process id")
    return NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode").last
  }

  ///  Called when the extension has applied the edit.
  func fileChangeApplied(withError error: String?) {
    if let error {
      defaultLogger.log("Extension has failed to apply the edit.")
      // TODO: make this parsing more type safe.
      let errorData = error.utf8Data
      if
        let errorObject = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
        let bufferContent = errorObject["bufferContent"] as? String,
        let expectedContent = errorObject["expectedContent"] as? String
      {
        let diff = try? FileDiff.getGitDiff(oldContent: bufferContent, newContent: expectedContent)
        defaultLogger.error("Edit failed due to mismatched content: \(diff ?? "could not compare")")
      } else {
        defaultLogger.error("Edit failed: \(error)")
      }
    } else {
      defaultLogger.log("Extension has succesfully applied the edit.")
    }

    let currentContinuation = inLock { state in
      let currentContinuation = state.currentContinuation
      state.currentContinuation = nil
      state.fileChange = nil
      return currentContinuation
    }
    if let error {
      currentContinuation?.resume(throwing: AppError(message: error))
    } else {
      currentContinuation?.resume(returning: ())
    }
  }

}

// MARK: DefaultXcodeController + AppleScript
extension DefaultXcodeController {

  @MainActor
  static func run(appleScript: String) throws {
    guard let script = NSAppleScript(source: appleScript) else {
      assertionFailure("Could not create NSAppleScript object.")
      throw AppError(message: "Could not create NSAppleScript object.")
    }

    var errorDict: NSDictionary?
    script.executeAndReturnError(&errorDict)

    if let error = errorDict {
      defaultLogger.error("AppleScript Error: \(error)")
      throw AppError(message: "AppleScript Error: \(error)")
    }
  }

  @MainActor
  static func activateXcodeWithAppleScript() throws {
    try run(appleScript: """
        tell application "Xcode" to activate
        delay 0.1
      """)
  }

  /// Modify the content of the file using Apple Script. This might lead to a non ideal UX with the code moving around in the editor but is a good fallback.
  @MainActor
  private static func openFileWithAppleScript(at path: URL) throws {
    try run(appleScript: """
      tell application "Xcode"
          set theFilePath to "\(path.path)"
          open theFilePath
          repeat 10 times
              try
                  set doc to first source document whose path is theFilePath
                  exit repeat
              on error
                  delay 0.1
              end try
          end repeat
      end tell
      delay 0.1
      """)
  }

  /// Modify the content of the file using Apple Script. This might lead to a non ideal UX with the code moving around in the editor but is a good fallback.
  @MainActor
  private static func modifyFile(at path: URL, with newContent: String) throws {
    let pasteboard = NSPasteboard.general
    let pasteboardContent = pasteboard.pasteboardItems
    pasteboard.clearContents()
    pasteboard.writeObjects([newContent as NSPasteboardWriting])

    defer {
      // Reset the content of the pasteboard.
      let copies = pasteboardContent?.map { item in
        let copy = NSPasteboardItem()
        for type in item.types {
          if let data = item.data(forType: type) {
            copy.setData(data, forType: type)
          }
        }
        return copy
      }
      _ = copies.map(pasteboard.writeObjects)
    }

    try activateXcodeWithAppleScript()
    try openFileWithAppleScript(at: path)

    try run(appleScript: """
      tell application "Xcode"
          tell application "System Events"
            keystroke "a" using command down
            keystroke "v" using command down
          end tell
      end tell
      """)

    defaultLogger.log("Successfully updated '\(path.path)' in Xcode.")
  }
}

extension BaseProviding where
  Self: XcodeObserverProviding,
  Self: AppEventHandlerRegistryProviding,
  Self: ShellServiceProviding,
  Self: SettingsServiceProviding,
  Self: FileManagerProviding
{
  public var xcodeController: XcodeController {
    shared {
      DefaultXcodeController(
        appEventHandlerRegistry: appEventHandlerRegistry,
        shellService: shellService,
        xcodeObserver: xcodeObserver,
        settingsService: settingsService,
        fileManager: fileManager)
    }
  }
}

extension ShellService {
  /// Returns whether the instance  (assumed to be an Xcode instance) is the one launched by running the extension.
  func isXcodeInstanceUsedByDebugExtension(processIdentifier: pid_t) async -> Bool {
    do {
      return try await stdout("ps aux | grep \(processIdentifier)")?.contains("-NSDocumentRevisionsDebugMode YES") ?? false
    } catch {
      return false
    }
  }
}
