// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import SwiftUI

extension CGFloat {
  public static let bodySize = NSFont.preferredFont(forTextStyle: .body).pointSize
}

extension NSFont {
  public static let body = NSFont.preferredFont(forTextStyle: .body)
}

// MARK: - NSFontKey

/// An environment key for providing an NSFont to SwiftUI views
struct NSFontKey: EnvironmentKey {
  /// The default value for the NSFont environment key
  static let defaultValue: NSFont? = nil
}

// MARK: - Environment Extensions

extension EnvironmentValues {
  /// Access the NSFont environment value
  public var nsFont: NSFont? {
    get { self[NSFontKey.self] }
    set { self[NSFontKey.self] = newValue }
  }
}

// MARK: - View Extension

extension View {
  /// Sets the NSFont for this view and its child views
  public func font(_ font: NSFont?) -> some View {
    environment(\.nsFont, font)
      .environment(\.font, font.map { Font($0) })
  }
}

extension NSAttributedString {
  public func with(color: NSColor) -> NSAttributedString {
    let mutableSelf = NSMutableAttributedString(attributedString: self)
    let range = NSRange(location: 0, length: mutableSelf.length)
    mutableSelf.addAttribute(.foregroundColor, value: color, range: range)
    return mutableSelf
  }
}

extension AttributedString {
  public func with(color: NSColor) -> AttributedString {
    AttributedString(NSAttributedString(self).with(color: color))
  }
}
