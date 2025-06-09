// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Foundation

extension Bundle {

  /// The name of the Xcode extension.
  public var xcodeExtensionName: String {
    // We use an invisible non unicode character in the extension name to allow for it to have the ~same name as the main app.
    (infoDictionary?["XCODE_EXTENSION_PRODUCT_NAME"] as? String)?.trimmingLeadingNonUnicodeCharacters ?? "command"
  }

  /// The bundle identifier for the host app. This is also the prefix of any identifier for other targets.
  public var hostAppBundleId: String {
    infoDictionary?["APP_BUNDLE_IDENTIFIER"] as? String ?? "dev.getcmd.command"
  }

  /// The bundle identifier for the RELEASE host app. This is also the prefix of any identifier for other targets in RELEASE.
  public var releaseHostAppBundleId: String {
    infoDictionary?["RELEASE_APP_BUNDLE_IDENTIFIER"] as? String ?? "dev.getcmd.command"
  }
}

extension String {
  fileprivate var trimmingLeadingNonUnicodeCharacters: String {
    String(drop(while: { $0.unicodeScalars.contains(where: { CharacterSet.alphanumerics.inverted.contains($0) }) }))
  }
}
