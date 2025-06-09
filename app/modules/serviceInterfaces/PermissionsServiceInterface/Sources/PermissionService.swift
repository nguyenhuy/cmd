// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Combine
import ConcurrencyFoundation

// MARK: - Permission

public enum Permission {
  case accessibility
  case xcodeExtension
}

// MARK: - PermissionsService

public protocol PermissionsService: Sendable {
  /// Prompt the user to grant the desired permission.
  func request(permission: Permission)

  /// Check if the permission is granted. The publisher will be updated as the permissions status changes.
  func status(for permission: Permission) -> ReadonlyCurrentValueSubject<Bool?, Never>
}

// MARK: - PermissionsServiceProviding

public protocol PermissionsServiceProviding {
  var permissionsService: PermissionsService { get }
}
