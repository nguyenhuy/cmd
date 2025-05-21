// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventServiceInterface
import Dependencies
import ExtensionEventsInterface
import LoggingServiceInterface
import SharedValuesFoundation
import ShellServiceInterface
import XcodeObserverServiceInterface

// MARK: - ExtensionCommandHandler

// TODO: Remove @unchecked when https://github.com/pointfreeco/swift-dependencies/discussions/267 is fixed
public final class ExtensionCommandHandler: @unchecked Sendable {

  public init() {
    appEventHandlerRegistry.registerHandler { [weak self] event in
      await self?.handle(appEvent: event) ?? false
    }
  }

  @Dependency(\.appEventHandlerRegistry) private var appEventHandlerRegistry
  @Dependency(\.shellService) private var shellService
  @Dependency(\.xcodeObserver) private var xcodeObserver

  private func handle(appEvent: AppEvent) async -> Bool {
    if let appEvent = appEvent as? ExecuteExtensionRequestEvent {
      do {
        switch appEvent.command {
        case ExtensionCommandKeys.openInCursor:
          let xcodeState = xcodeObserver.state
          guard let currentFile = xcodeState.focusedTabURL else {
            defaultLogger.error("No active file found")
            return false
          }
          var lineDescriptor = ""
          if
            let line = xcodeState.focusedWorkspace?.editors.first(where: {
              $0.fileName == currentFile.lastPathComponent
            })?.selections.first?.start.line
          {
            lineDescriptor = ":\(line + 1)"
          }

          try await shellService
            .run(
              "/Applications/Cursor.app/Contents/Resources/app/bin/code -g \"\(currentFile.path(percentEncoded: false))\(lineDescriptor)\"",
              useInteractiveShell: false)
          defaultLogger.log("Completed command")
          appEvent.completion(.success(EmptyResult()))
          return true

        default:
          return false
        }
      } catch {
        defaultLogger.error("Error running shell command: \(error)")
        appEvent.completion(.failure(error))
      }
    }
    return false
  }
}

// MARK: - EmptyResult

private struct EmptyResult: Encodable { }
