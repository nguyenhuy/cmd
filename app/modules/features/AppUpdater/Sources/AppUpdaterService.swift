// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Combine
import ConcurrencyFoundation
import LoggingServiceInterface
import Sparkle
import ThreadSafe

// MARK: - AppUpdaterService

public final class AppUpdaterService: @unchecked Sendable {

  public static let shared = AppUpdaterService()

  public func checkForUpdates() {
    updater = _AppUpdaterService()
    updater.checkForUpdates()
  }

//  public func checkForUpdatesSilently() {
//      updater.checkForUpdatesSilently()
//  }

  var updater = _AppUpdaterService()

}

// MARK: - _AppUpdaterService

final class _AppUpdaterService: NSObject, @unchecked Sendable {
  override init() {
    super.init()
    setup()
    checkForUpdates()
  }

  func checkForUpdates() {
    if updater?.sessionInProgress == true {
      defaultLogger.log("Update check already in progress")

    } else {
      updater?.checkForUpdates()
    }
  }

  func checkForUpdatesSilently() {
    updater?.checkForUpdatesInBackground()
  }

  private var updater: SPUUpdater?

  private func setup() {
    let hostBundle = Bundle.main
    let applicationBundle = Bundle.main
    let userDriver = SilentUserDriver()

    updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: userDriver,
      delegate: self)
    defaultLogger.log("feedurl \(updater?.feedURL?.absoluteString ?? "nil")")
    UserDefaults.standard.removeObject(forKey: "SULastCheckTime")

    try? updater?.start()
    updater?.resetUpdateCycle()
  }

}

// MARK: SPUUpdaterDelegate

extension _AppUpdaterService: SPUUpdaterDelegate {
  func updaterShouldPromptForPermissionToCheck(forUpdates _: SPUUpdater) -> Bool {
    defaultLogger.log("updaterShouldPromptForPermissionToCheck(forUpdates:)")
    return false
  }

  func updater(_: SPUUpdater, didDownloadUpdate _: SUAppcastItem) {
    defaultLogger.log("updater(_:didDownloadUpdate:)")
  }

  func updater(_: SPUUpdater, didExtractUpdate _: SUAppcastItem) {
    defaultLogger.log("updater(_:didExtractUpdate:)")
  }

  func updater(_: SPUUpdater, shouldProceedWithUpdate _: SUAppcastItem, updateCheck _: SPUUpdateCheck) throws {
    defaultLogger.log("updater(_:shouldProceedWithUpdate:updateCheck:)")
  }

  func updater(
    _: SPUUpdater,
    willInstallUpdateOnQuit _: SUAppcastItem,
    immediateInstallationBlock _: @escaping () -> Void)
    -> Bool
  {
    true
  }

  func updater(_: SPUUpdater, mayPerform _: SPUUpdateCheck) throws {
    defaultLogger.log("updater(_:mayPerform:)")
  }

  func updaterDidNotFindUpdate(_: SPUUpdater, error: any Error) {
    defaultLogger.error("updaterDidNotFindUpdate(_:error:)", error)
  }

  func updaterWillRelaunchApplication(_: SPUUpdater) {
    defaultLogger.log("updaterWillRelaunchApplication(_:)")
  }

  func bestValidUpdate(in appCast: SUAppcast, for _: SPUUpdater) -> SUAppcastItem? {
    defaultLogger.log("bestValidUpdate(in:for:)")
    return appCast.items.first
  }

  func updaterMayCheck(forUpdates _: SPUUpdater) -> Bool {
    defaultLogger.log("updaterMayCheck(forUpdates:)")
    return true
  }
}

// MARK: - SilentUserDriver

final class SilentUserDriver: NSObject, SPUUserDriver {

  func show(_: SPUUpdatePermissionRequest) async -> SUUpdatePermissionResponse {
    defaultLogger.log("[AppUpdater] Showing update permission request")
    return SUUpdatePermissionResponse(automaticUpdateChecks: true, automaticUpdateDownloading: true, sendSystemProfile: false)
  }

  func showUpdateReleaseNotes(with _: SPUDownloadData) {
    defaultLogger.log("[AppUpdater] Showing update release notes")
  }

  func showUpdateReleaseNotesFailedToDownloadWithError(_ error: any Error) {
    defaultLogger.log("[AppUpdater] Failed to download release notes: \(error.localizedDescription)")
  }

  func showUpdateNotFoundWithError(_ error: any Error, acknowledgement _: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] Update not found with error: \(error.localizedDescription)")
  }

  func showDownloadInitiated(cancellation _: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] Download initiated")
  }

  func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
    defaultLogger.log("[AppUpdater] Download expected content length: \(expectedContentLength) bytes")
  }

  func showDownloadDidReceiveData(ofLength length: UInt64) {
    defaultLogger.log("[AppUpdater] Download received data: \(length) bytes")
  }

  func showDownloadDidStartExtractingUpdate() {
    defaultLogger.log("[AppUpdater] Started extracting update")
  }

  func showExtractionReceivedProgress(_ progress: Double) {
    defaultLogger.log("[AppUpdater] Extraction progress: \(Int(progress * 100))%")
  }

  func showReadyToInstallAndRelaunch() async -> SPUUserUpdateChoice {
    defaultLogger.log("[AppUpdater] Ready to install and relaunch - dismissing")
    return SPUUserUpdateChoice.dismiss
  }

  func showInstallingUpdate(
    withApplicationTerminated applicationTerminated: Bool,
    retryTerminatingApplication _: @escaping () -> Void)
  {
    defaultLogger.log("[AppUpdater] Installing update (app terminated: \(applicationTerminated))")
  }

  func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement _: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] Update installed and relaunched: \(relaunched)")
  }

  func showUpdateInFocus() {
    defaultLogger.log("[AppUpdater] Update in focus")
  }

  func showUserInitiatedUpdateCheck(cancellation completion: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] User initiated update check")
    completion()
  }

  func showUpdateFound(
    with updateItem: SUAppcastItem,
    state _: SPUUserUpdateState,
    reply: @escaping (SPUUserUpdateChoice) -> Void)
  {
    defaultLogger.log("[AppUpdater] Update found: \(updateItem.displayVersionString) (\(updateItem.versionString))")
    reply(.install)
  }

  func showDownloadedUpdate(_ updateItem: SUAppcastItem, acknowledgement: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] Update downloaded: \(updateItem.displayVersionString)")
    acknowledgement()
  }

  func showInstallingUpdate(withApplicationTerminated terminated: Bool) {
    defaultLogger.log("[AppUpdater] Installing update (app terminated: \(terminated))")
  }

  func showUpdateInstallationDidFinish() {
    defaultLogger.log("[AppUpdater] Update installation finished")
  }

  func showUpdateInstallationDidCancel() {
    defaultLogger.log("[AppUpdater] Update installation cancelled")
  }

  func dismissUpdateInstallation() {
    defaultLogger.log("[AppUpdater] Dismissing update installation")
  }

  func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] Updater error: \(error.localizedDescription)")
    acknowledgement()
  }

  func showUpdateNotFoundAcknowledgement(completion: @escaping () -> Void) {
    defaultLogger.log("[AppUpdater] No update found - app is up to date")
    completion()
  }
}
