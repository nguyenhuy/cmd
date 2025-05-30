// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - XcodeControllerDependencyKey

public final class XcodeControllerDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: XcodeController = MockXcodeController()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: XcodeController = () as! XcodeController
  #endif
}

extension DependencyValues {
  public var xcodeController: XcodeController {
    get { self[XcodeControllerDependencyKey.self] }
    set { self[XcodeControllerDependencyKey.self] = newValue }
  }
}
