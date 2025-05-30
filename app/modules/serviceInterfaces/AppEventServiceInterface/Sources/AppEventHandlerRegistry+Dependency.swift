// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies

// MARK: - AppEventHandlerRegistryDependencyKey

public final class AppEventHandlerRegistryDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: AppEventHandlerRegistry = MockAppEventHandlerRegistry()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: AppEventHandlerRegistry = () as! AppEventHandlerRegistry
  #endif
}

extension DependencyValues {
  public var appEventHandlerRegistry: AppEventHandlerRegistry {
    get { self[AppEventHandlerRegistryDependencyKey.self] }
    set { self[AppEventHandlerRegistryDependencyKey.self] = newValue }
  }
}
