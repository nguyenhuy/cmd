// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Observation
import SwiftTesting
import Testing

@testable import PermissionsServiceInterface

struct MockPermissionsServiceTests {
  @Test
  func test_usesInitialValues() async throws {
    let sut = MockPermissionsService(grantedPermissions: [.accessibility])
    #expect(sut.status(for: .accessibility).currentValue == true)
    #expect(sut.status(for: .xcodeExtension).currentValue == false)
  }

  @Test
  func test_updateSubscriberWithNewValues() async throws {
    let sut = MockPermissionsService(grantedPermissions: [.accessibility])

    let exp = expectation(description: "Xcode extension permission granted")
    let cancellable = sut.status(for: .xcodeExtension).sink { status in
      if status == true {
        exp.fulfill()
      }
    }
    #expect(exp.isFulfilled == false)
    Task { @MainActor in
      sut.set(permission: .xcodeExtension, granted: true)
    }
    try await fulfillment(of: exp)

    _ = cancellable
  }
}
