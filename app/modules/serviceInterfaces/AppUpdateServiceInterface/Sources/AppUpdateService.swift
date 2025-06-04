// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation

// MARK: - AppUpdateInfo

public struct AppUpdateInfo: Sendable, Equatable {
  public let version: String
  public let fileURL: URL?
  public let releaseNotesURL: URL?

  public init(version: String, fileURL: URL?, releaseNotesURL: URL?) {
    self.version = version
    self.fileURL = fileURL
    self.releaseNotesURL = releaseNotesURL
  }
}

// MARK: - AppUpdateResult

public enum AppUpdateResult: Sendable, Equatable {
  case noUpdateAvailable
  case updateAvailable(info: AppUpdateInfo?)
}

// MARK: - AppUpdateService

public protocol AppUpdateService: Sendable {
  /// Relaunch the application
  func relaunch()
  /// Stop checking for updates
  func stopCheckingForUpdates()
  /// Keep checking for updates in the background at regular intervals. When an update is available, download it.
  func checkForUpdatesContinously()
  /// Whether there an app update has been installed.
  var hasUpdateAvailable: ReadonlyCurrentValueSubject<AppUpdateResult, Never> { get }
  /// Skip the current update
  func skip(update: AppUpdateInfo?)
  /// Return whether a given update is skipped.
  func isUpdateSkipped(_ update: AppUpdateInfo?) -> Bool
}

// MARK: - AppUpdateServiceProviding

public protocol AppUpdateServiceProviding {
  var appUpdateService: AppUpdateService { get }
}
