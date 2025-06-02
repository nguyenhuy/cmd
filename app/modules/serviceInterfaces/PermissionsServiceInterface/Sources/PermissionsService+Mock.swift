// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation
import ThreadSafe

#if DEBUG
@ThreadSafe
public final class MockPermissionsService: PermissionsService {

  public init(grantedPermissions: [Permission] = []) {
    isAccessibilityPermissionGranted = .init(grantedPermissions.contains(.accessibility))
    isXcodeExtensionPermissionGranted = .init(grantedPermissions.contains(.xcodeExtension))
  }

  public var onRequestAccessibilityPermission: (@Sendable () -> Void)?
  public var onRequestXcodeExtensionPermission: (@Sendable () -> Void)?

  public func request(permission: Permission) {
    switch permission {
    case .accessibility:
      Task { @MainActor in
        onRequestAccessibilityPermission?()
      }

    case .xcodeExtension:
      Task { @MainActor in
        onRequestXcodeExtensionPermission?()
      }
    }
  }

  public func status(for permission: Permission) -> ReadonlyCurrentValueSubject<Bool?, Never> {
    switch permission {
    case .accessibility:
      isAccessibilityPermissionGranted.readonly(removingDuplicate: true)
    case .xcodeExtension:
      isXcodeExtensionPermissionGranted.readonly(removingDuplicate: true)
    }
  }

  @MainActor
  public func set(permission: Permission, granted: Bool) {
    switch permission {
    case .accessibility:
      isAccessibilityPermissionGranted.send(granted)
    case .xcodeExtension:
      isXcodeExtensionPermissionGranted.send(granted)
    }
  }

  private let isAccessibilityPermissionGranted: CurrentValueSubject<Bool?, Never>

  private let isXcodeExtensionPermissionGranted: CurrentValueSubject<Bool?, Never>

}
#endif
