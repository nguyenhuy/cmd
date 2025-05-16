// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DependencyFoundation
import Foundation

// MARK: - UserDefaultsProviding

public protocol UserDefaultsProviding: BaseProviding {
  var sharedUserDefaults: UserDefaultsI { get }
}

// MARK: - SharedUserDefaultsDependencyKey

public final class SharedUserDefaultsDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: UserDefaultsI = Foundation.UserDefaults.standard
  #else
  /// This is not read outside of DEBUG
  public static let testValue: UserDefaultsI = () as! UserDefaults
  #endif
}

extension DependencyValues {
  public var userDefaults: UserDefaultsI {
    get { self[SharedUserDefaultsDependencyKey.self] }
    set { self[SharedUserDefaultsDependencyKey.self] = newValue }
  }
}
