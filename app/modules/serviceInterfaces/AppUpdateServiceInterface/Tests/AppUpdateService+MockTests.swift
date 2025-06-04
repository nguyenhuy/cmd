// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftTesting
import Testing

@testable import AppUpdateServiceInterface

struct MockAppUpdateServiceTests {
  @Test
  func test_usesInitialValues() async throws {
    let updateInfo = AppUpdateInfo(version: "1.0.0", fileURL: nil, releaseNotesURL: nil)
    let sut = MockAppUpdateService(hasUpdateAvailable: .updateAvailable(info: updateInfo))

    if case .updateAvailable(let info) = sut.hasUpdateAvailable.currentValue {
      #expect(info?.version == "1.0.0")
    } else {
      Issue.record("Expected updateAvailable")
    }
  }

  @Test
  func test_defaultInitialValue() async throws {
    let sut = MockAppUpdateService()
    #expect(sut.hasUpdateAvailable.currentValue == .noUpdateAvailable)
  }

  @Test
  func test_updateSubscriberWithNewValues() async throws {
    let sut = MockAppUpdateService(hasUpdateAvailable: .noUpdateAvailable)

    let exp = expectation(description: "Update becomes available")
    let cancellable = sut.hasUpdateAvailable.sink { result in
      if case .updateAvailable = result {
        exp.fulfill()
      }
    }
    #expect(exp.isFulfilled == false)

    let updateInfo = AppUpdateInfo(version: "2.0.0", fileURL: nil, releaseNotesURL: nil)
    sut.setUpdateAvailable(.updateAvailable(info: updateInfo))
    try await fulfillment(of: exp)

    _ = cancellable
  }

  @Test
  func test_relaunchCallsCallback() async throws {
    let sut = MockAppUpdateService()
    let exp = expectation(description: "Relaunch called")

    sut.onRelaunch = {
      exp.fulfill()
    }

    sut.relaunch()
    try await fulfillment(of: exp)
  }

  @Test
  func test_stopCheckingForUpdatesCallsCallback() async throws {
    let sut = MockAppUpdateService()
    let exp = expectation(description: "Stop checking called")

    sut.onStopCheckingForUpdates = {
      exp.fulfill()
    }

    sut.stopCheckingForUpdates()
    try await fulfillment(of: exp)
  }

  @Test
  func test_checkForUpdatesContinuouslyCallsCallback() async throws {
    let sut = MockAppUpdateService()
    let exp = expectation(description: "Check continuously called")

    sut.onCheckForUpdatesContinuously = {
      exp.fulfill()
    }

    sut.checkForUpdatesContinously()
    try await fulfillment(of: exp)
  }

  @Test
  func test_skipUpdateCallsCallback() async throws {
    let sut = MockAppUpdateService()
    let exp = expectation(description: "Skip update called")
    let updateInfo = AppUpdateInfo(version: "1.5.0", fileURL: nil, releaseNotesURL: nil)

    sut.onSkipUpdate = { version in
      #expect(version?.version == "1.5.0")
      exp.fulfill()
    }

    sut.skip(update: updateInfo)
    try await fulfillment(of: exp)
  }

  @Test
  func test_skipUpdateSetsNoUpdateAvailable() async throws {
    let updateInfo = AppUpdateInfo(version: "1.0.0", fileURL: nil, releaseNotesURL: nil)
    let sut = MockAppUpdateService(hasUpdateAvailable: .updateAvailable(info: updateInfo))

    // Initially has update available
    if case .updateAvailable = sut.hasUpdateAvailable.currentValue {
      // Expected
    } else {
      Issue.record("Expected updateAvailable initially")
    }

    let exp = expectation(description: "Update becomes unavailable")
    let cancellable = sut.hasUpdateAvailable.sink { result in
      if result == .noUpdateAvailable {
        exp.fulfill()
      }
    }

    let skipInfo = AppUpdateInfo(version: "1.0.0", fileURL: nil, releaseNotesURL: nil)
    sut.skip(update: skipInfo)
    try await fulfillment(of: exp)

    #expect(sut.hasUpdateAvailable.currentValue == .noUpdateAvailable)
    _ = cancellable
  }

  @Test
  func test_skipUpdateWithNilVersion() async throws {
    let sut = MockAppUpdateService()
    let exp = expectation(description: "Skip update called with nil")

    sut.onSkipUpdate = { version in
      #expect(version == nil)
      exp.fulfill()
    }

    sut.skip(update: nil)
    try await fulfillment(of: exp)
  }
}
