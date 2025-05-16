// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import Foundation

// MARK: - SharedUserDefaultsDependencyKey + DependencyKey

extension SharedUserDefaultsDependencyKey: DependencyKey {
  public static var liveValue: any UserDefaultsI { AppExtensionScope.shared.sharedUserDefaults }
}

// MARK: - AppExtensionScope + UserDefaultsProviding

extension AppExtensionScope: UserDefaultsProviding {
  public var sharedUserDefaults: any UserDefaultsI {
    shared {
      do {
        guard let userDefaults = try UserDefaults.shared(bundle: Bundle(for: AppExtensionScope.self)) else {
          return Foundation.UserDefaults.standard
        }
        return userDefaults
      } catch {
        return Foundation.UserDefaults.standard
      }
    }
  }

}
