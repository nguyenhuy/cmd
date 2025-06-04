// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockAppUpdateService: AppUpdateService {

  public init(hasUpdateAvailable: AppUpdateResult = .noUpdateAvailable) {
    _hasUpdateAvailable = .init(hasUpdateAvailable)
  }

  public var onRelaunch: (@Sendable () -> Void)?
  public var onStopCheckingForUpdates: (@Sendable () -> Void)?
  public var onCheckForUpdatesContinuously: (@Sendable () -> Void)?

  public var hasUpdateAvailable: ReadonlyCurrentValueSubject<AppUpdateResult, Never> {
    _hasUpdateAvailable.readonly()
  }

  public func relaunch() {
    onRelaunch?()
  }

  public func stopCheckingForUpdates() {
    onStopCheckingForUpdates?()
  }

  public func checkForUpdatesContinously() {
    onCheckForUpdatesContinuously?()
  }

  public func setUpdateAvailable(_ result: AppUpdateResult) {
    _hasUpdateAvailable.send(result)
  }

  private let _hasUpdateAvailable: CurrentValueSubject<AppUpdateResult, Never>

}
#endif
