// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Foundation
import Security

// MARK: - KeychainHelper

class KeychainHelper {

  @discardableResult
  static func save(key: String, value: String) -> Bool {
    let data = value.utf8Data
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    SecItemDelete(query as CFDictionary) // Remove any existing item
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  static func load(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecSuccess, let data = result as? Data {
      return String(data: data, encoding: .utf8)
    }
    return nil
  }

  @discardableResult
  static func delete(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
  }

  private static let service = UserDefaults.sharedSuiteName(bundle: .main) ?? "com.xcompanion.keychain"

}

extension UserDefaults {

  public func securelySave(_ value: String, forKey key: String) {
    KeychainHelper.save(key: key, value: value)
  }

  public func loadSecuredValue(forKey key: String) -> String? {
    KeychainHelper.load(key: key)
  }

  public func removeSecuredValue(forKey key: String) {
    KeychainHelper.delete(key: key)
  }
}
