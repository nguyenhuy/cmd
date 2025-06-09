// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies

// MARK: - XcodeObserverDependencyKey

public final class XcodeObserverDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: XcodeObserver = MockXcodeObserver(.unknown)
  #else
  /// This is not read outside of DEBUG
  public static let testValue: XcodeObserver = () as! XcodeObserver
  #endif
}

extension DependencyValues {
  public var xcodeObserver: XcodeObserver {
    get { self[XcodeObserverDependencyKey.self] }
    set { self[XcodeObserverDependencyKey.self] = newValue }
  }
}
