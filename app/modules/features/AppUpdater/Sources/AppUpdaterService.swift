// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

//// Copyright command. All rights reserved.
//// Licensed under the XXX License. See License.txt in the project root for license information.
//
// @preconcurrency import Combine
// import ConcurrencyFoundation
// import AppFoundation
// import LoggingServiceInterface
// @preconcurrency import Sparkle
// import ThreadSafe
//
// let updateLogger = defaultLogger.subLogger(subsystem: "appUpdate")
//
//
//
// public enum AppUpdateResult: Sendable {
//    case noUpdateAvailable
//    case updateAvailable(info: SUAppcastItem?)
// }
//
//// MARK: - AppUpdateService
//
// public protocol AppUpdateService: Sendable {
//    /// Relaunch the application
//    func relaunch()
//    /// Stop checking for updates
//    func stopCheckingForUpdates()
//    /// Keep checking for updates in the background at regular intervals. When an update is available, download it.
//    func checkForUpdatesContinously()
//    /// Whether will be updated if it is restarted.
//    var hasUpdateAvailable: ReadonlyCurrentValueSubject<AppUpdateResult, Never> { get }
// }
//
// @ThreadSafe
// final class DefaultAppUpdateService: AppUpdateService {
//    func stopCheckingForUpdates() {
//        canCheckForUpdates = false
//    }
//
//    private let delayBetweenChecks: Duration = .seconds(60)
//
//    func checkForUpdatesContinously() {
//        canCheckForUpdates = true
//        startCheckingForUpdates()
//    }
//
//    var hasUpdateAvailable: ConcurrencyFoundation.ReadonlyCurrentValueSubject<AppUpdateResult, Never> {
//        _hasUpdateAvailable.readonly()
//    }
//
//    private let _hasUpdateAvailable = CurrentValueSubject<AppUpdateResult, Never>(.noUpdateAvailable)
//    init() {}
//
//    private var canCheckForUpdates: Bool = false
//    private var updateTask: Task<Void, Error>?
//
//    private func startCheckingForUpdates() {
//        updateTask?.cancel()
//        updateTask = Task { [weak self] in
//            while let self, self.canCheckForUpdates {
//                try Task.checkCancellation()
//                let updater = UpdateChecker()
//                self._hasUpdateAvailable.send(try await updater.checkForUpdates())
//                try await Task.sleep(for: delayBetweenChecks)
//            }
//        }
//    }
//
//    func relaunch() {
//        guard let bundlePath = Bundle.main.resourcePath else {
//            return
//        }
//        let url = URL(fileURLWithPath: bundlePath)
//        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
//        let task = Process()
//        task.launchPath = "/usr/bin/open"
//        task.arguments = [path]
//        task.launch()
//        exit(0)
//    }
//
// }
//
//// MARK: - _AppUpdateService
//
///// A helper that checks for updates once.
// @ThreadSafe
// final class UpdateChecker: NSObject, Sendable {
//
//  override init() {
//    super.init()
//
//        let hostBundle = Bundle.main
//        let applicationBundle = Bundle.main
//      let userDriver = BackgroundUserDriver(
//        onReceivedUpdateInfo: { [weak self] updateInfo in self?.updateInfo = updateInfo },
//        onReadyToInstall: { [weak self] in self?.complete(with: .success(.updateAvailable(info: self?.updateInfo))) })
//
//        updater = SPUUpdater(
//          hostBundle: hostBundle,
//          applicationBundle: applicationBundle,
//          userDriver: userDriver,
//          delegate: self)
//  }
//
//    private var updateInfo: SUAppcastItem?
//
//    func checkForUpdates() async throws -> AppUpdateResult {
//        if updater?.sessionInProgress == true {
//            throw AppError("Update already in progress")
//        }
//        let (future, continuation) = Future<AppUpdateResult, Error>.make()
//        let canContinue = self.inLock { state in
//            guard state.continuation == nil else {
//                return false
//            }
//            self.continuation = continuation
//        }
//        if !canContinue {
//            continuation(.failure(AppError("Update already in progress")))
//            return try await future.value
//        }
//
//
//    /// Remove the key used by Sparkle to avoid the update being delayed / cached.
//      UserDefaults.standard.removeObject(forKey: "SULastCheckTime")
//
//        try? updater?.start()
//        updater?.resetUpdateCycle()
//        updater?.checkForUpdatesInBackground()
//
//        return try await future.value
//  }
//
//    private func complete(with result: Result<AppUpdateResult, Error>) {
//        let continuation = self.inLock { state in
//            let continuation = state.continuation
//            state.continuation = nil
//            return continuation
//        }
//        continuation?(result)
//    }
//
//  private var updater: SPUUpdater?
//    private var continuation: (@Sendable (Result<AppUpdateResult, Error>) -> Void)?
// }
//
//// MARK: SPUUpdaterDelegate
//
// extension UpdateChecker: SPUUpdaterDelegate {
//  func updaterShouldPromptForPermissionToCheck(forUpdates _: SPUUpdater) -> Bool {
//    updateLogger.log("updaterShouldPromptForPermissionToCheck(forUpdates:)")
//    return false
//  }
//
//  func updater(_: SPUUpdater, didDownloadUpdate _: SUAppcastItem) {
//    updateLogger.log("updater(_:didDownloadUpdate:)")
//  }
//
//  func updater(_: SPUUpdater, didExtractUpdate _: SUAppcastItem) {
//    updateLogger.log("updater(_:didExtractUpdate:)")
//  }
//
//  func updater(_: SPUUpdater, shouldProceedWithUpdate _: SUAppcastItem, updateCheck _: SPUUpdateCheck) throws {
//    updateLogger.log("updater(_:shouldProceedWithUpdate:updateCheck:)")
//  }
//
//  func updater(
//    _: SPUUpdater,
//    willInstallUpdateOnQuit _: SUAppcastItem,
//    immediateInstallationBlock _: @escaping () -> Void)
//    -> Bool
//  {
//    true
//  }
//
//  func updater(_: SPUUpdater, mayPerform _: SPUUpdateCheck) throws {
//    updateLogger.log("updater(_:mayPerform:)")
//  }
//
//  func updaterDidNotFindUpdate(_: SPUUpdater, error: any Error) {
//    defaultLogger.error("updaterDidNotFindUpdate(_:error:)", error)
//      complete(with: .success(.noUpdateAvailable))
//  }
//
//  func updaterWillRelaunchApplication(_: SPUUpdater) {
//    updateLogger.log("updaterWillRelaunchApplication(_:)")
//  }
//
//  func bestValidUpdate(in appCast: SUAppcast, for _: SPUUpdater) -> SUAppcastItem? {
//    updateLogger.log("bestValidUpdate(in:for:)")
//    return appCast.items.first
//  }
//
//  func updaterMayCheck(forUpdates _: SPUUpdater) -> Bool {
//    updateLogger.log("updaterMayCheck(forUpdates:)")
//    return true
//  }
// }
//
//// MARK: - BackgroundUserDriver
//
///// A Sparkle's user driver that is not shown to the user (works in the background)
// final class BackgroundUserDriver: NSObject, SPUUserDriver, Sendable {
//
//    init(
//        onReceivedUpdateInfo: @escaping @Sendable (SUAppcastItem) -> Void = { _ in },
//        onReadyToInstall: @escaping @Sendable () -> Void = {}) {
//            self.onReceivedUpdateInfo = onReceivedUpdateInfo
//        self.onReadyToInstall = onReadyToInstall
//    }
//
//    private let onReceivedUpdateInfo: @Sendable (SUAppcastItem) -> Void
//    private let onReadyToInstall: @Sendable () -> Void
//
//  func show(_: SPUUpdatePermissionRequest) async -> SUUpdatePermissionResponse {
//    updateLogger.log("Showing update permission request")
//    return SUUpdatePermissionResponse(automaticUpdateChecks: true, automaticUpdateDownloading: true, sendSystemProfile: false)
//  }
//
//  func showUpdateReleaseNotes(with releaseNotes: SPUDownloadData) {
//    updateLogger.log("Showing update release notes")
//  }
//
//  func showUpdateReleaseNotesFailedToDownloadWithError(_ error: any Error) {
//    updateLogger.log("Failed to download release notes: \(error.localizedDescription)")
//  }
//
//  func showUpdateNotFoundWithError(_ error: any Error, acknowledgement _: @escaping () -> Void) {
//    updateLogger.log("Update not found with error: \(error.localizedDescription)")
//  }
//
//  func showDownloadInitiated(cancellation _: @escaping () -> Void) {
//    updateLogger.log("Download initiated")
//  }
//
//  func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
//    updateLogger.log("Download expected content length: \(expectedContentLength) bytes")
//  }
//
//  func showDownloadDidReceiveData(ofLength length: UInt64) {
//    updateLogger.log("Download received data: \(length) bytes")
//  }
//
//  func showDownloadDidStartExtractingUpdate() {
//    updateLogger.log("Started extracting update")
//  }
//
//  func showExtractionReceivedProgress(_ progress: Double) {
//    updateLogger.log("Extraction progress: \(Int(progress * 100))%")
//  }
//
//  func showReadyToInstallAndRelaunch() async -> SPUUserUpdateChoice {
//    updateLogger.log("Ready to install and relaunch - dismissing")
//      onReadyToInstall()
//    return SPUUserUpdateChoice.dismiss
//  }
//
//  func showInstallingUpdate(
//    withApplicationTerminated applicationTerminated: Bool,
//    retryTerminatingApplication _: @escaping () -> Void)
//  {
//    updateLogger.log("Installing update (app terminated: \(applicationTerminated))")
//  }
//
//  func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement _: @escaping () -> Void) {
//    updateLogger.log("Update installed and relaunched: \(relaunched)")
//  }
//
//  func showUpdateInFocus() {
//    updateLogger.log("Update in focus")
//  }
//
//  func showUserInitiatedUpdateCheck(cancellation _: @escaping () -> Void) {
//    updateLogger.log("User initiated update check")
//      // Do not call completion here as this would cancel the update.
//  }
//
//  func showUpdateFound(
//    with updateItem: SUAppcastItem,
//    state _: SPUUserUpdateState,
//    reply: @escaping (SPUUserUpdateChoice) -> Void)
//  {
//    updateLogger.log("Update found: \(updateItem.displayVersionString) (\(updateItem.versionString))")
//      onReceivedUpdateInfo(updateItem)
//    reply(.install)
//  }
//
//  func showDownloadedUpdate(_ updateItem: SUAppcastItem, acknowledgement: @escaping () -> Void) {
//    updateLogger.log("Update downloaded: \(updateItem.displayVersionString)")
//    acknowledgement()
//  }
//
//  func showInstallingUpdate(withApplicationTerminated terminated: Bool) {
//    updateLogger.log("Installing update (app terminated: \(terminated))")
//  }
//
//  func showUpdateInstallationDidFinish() {
//    updateLogger.log("Update installation finished")
//  }
//
//  func showUpdateInstallationDidCancel() {
//    updateLogger.log("Update installation cancelled")
//  }
//
//  func dismissUpdateInstallation() {
//    updateLogger.log("Dismissing update installation")
//  }
//
//  func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
//    updateLogger.log("Updater error: \(error.localizedDescription)")
//    acknowledgement()
//  }
//
//  func showUpdateNotFoundAcknowledgement(completion: @escaping () -> Void) {
//    updateLogger.log("No update found - app is up to date")
//    completion()
//  }
// }
