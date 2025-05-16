// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import Foundation
import LoggingServiceInterface
import SwiftUI

public enum AttributedStringHelpers {
  public static func attributedStringFromHTML(
    _ htmlString: String,
    baseFontFamily: String = "-apple-system",
    baseFontSize: CGFloat = 11,
    baseFontColor: Color = .white,
    linkColor: Color = .blue)
    -> NSAttributedString?
  {
    let styledHTML = """
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: -apple-system, Helvetica, Arial, sans-serif;
              font-size: \(baseFontSize)px;
              color: \(baseFontColor.nsColor.hex);
            }
            a {
              color: \(linkColor.nsColor.hex);
              text-decoration: none; /* or underline if you prefer */
            }
          </style>
        </head>
        <body>
          \(htmlString)
        </body>
      </html>
      """

    guard let data = styledHTML.data(using: .utf8) else { return nil }
    do {
      let attrString = try NSMutableAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue,
        ],
        documentAttributes: nil)

      attrString.enumerateAttribute(.font, in: NSRange(location: 0, length: attrString.length)) { value, range, _ in
        if let oldFont = value as? NSFont {
          let newFontDescriptor = oldFont.fontDescriptor
            .withFamily(baseFontFamily)
            .withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits)

          if let newFont = NSFont(descriptor: newFontDescriptor, size: baseFontSize) {
            attrString.addAttribute(.font, value: newFont, range: range)
          }
        }
      }
      return attrString

    } catch {
      defaultLogger.error("Error converting HTML to NSAttributedString: \(error)")
      return nil
    }
  }
}
