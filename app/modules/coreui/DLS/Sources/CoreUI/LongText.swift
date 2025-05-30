// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import SwiftUI

// MARK: - LongText

/// Similar to `SwiftUI.Text`, but uses an NSTextView that is much more performant,
/// especially over long texts that will freeze in a `Text`.
public struct LongText: View {

  public init(_ text: NSAttributedString, maxWidth: CGFloat = .greatestFiniteMagnitude) {
    self.init(text, needColoring: false, maxWidth: maxWidth)
  }

  private init(_ text: NSAttributedString, needColoring: Bool, maxWidth: CGFloat) {
    self.text = text
    self.needColoring = needColoring
    self.maxWidth = maxWidth
  }

  public init(_ text: AttributedString, maxWidth: CGFloat = .greatestFiniteMagnitude) {
    self.init(NSAttributedString(text), needColoring: false, maxWidth: maxWidth)
  }

  public init(_ text: String, font: NSFont = .body, maxWidth: CGFloat = .greatestFiniteMagnitude) {
    let attrString = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
    let range = NSRange(location: 0, length: attrString.length)
    attrString.addAttribute(.font, value: font, range: range)

    self.init(attrString, needColoring: true, maxWidth: maxWidth)
  }

  public var body: some View {
    InnerLongText(attributedTextWithFont, maxWidth: maxWidth)
  }

  let text: NSAttributedString
  let needColoring: Bool
  let maxWidth: CGFloat

  static func size(for text: NSAttributedString, maxWidth: CGFloat) -> CGSize {
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    let textStorage = NSTextStorage()

    // Hook up the text system objects
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)

    textStorage.setAttributedString(text)
    textContainer.containerSize = NSSize(width: maxWidth, height: .greatestFiniteMagnitude)
    layoutManager.glyphRange(for: textContainer)
    let usedRect = layoutManager.usedRect(for: textContainer)
    return usedRect.integral.size
  }

  @Environment(\.colorScheme) private var colorScheme: ColorScheme

  @Environment(\.nsFont) private var environmentFont

  /// The attributed string modified with the environment font.
  private var attributedTextWithFont: NSAttributedString {
    if text.length == 0 {
      return text
    }
    guard environmentFont != nil || needColoring else {
      return text
    }

    let mutableText = NSMutableAttributedString(attributedString: text)
    let range = NSRange(location: 0, length: mutableText.length)

    if needColoring {
      // Coloring is done here instead of in the initializer,
      // since the environment variable for the color scheme is not available before.
      let color = colorScheme == .dark ? NSColor.white : NSColor.black
      if
        text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor != color
      {
        mutableText.addAttribute(.foregroundColor, value: color, range: range)
      }
    }

    if
      let fontToUse = environmentFont,
      text.attribute(.font, at: 0, effectiveRange: nil) as? NSFont != fontToUse
    {
      mutableText.addAttribute(.font, value: fontToUse, range: range)
    }

    return mutableText
  }

}

// MARK: - InnerLongText

/// Efficiently display an `NSAttributedString`.
public struct InnerLongText: View {

  public init(_ text: NSAttributedString, maxWidth: CGFloat) {
    self.text = text
    self.maxWidth = maxWidth
    textSize = LongText.size(for: text, maxWidth: maxWidth)
  }

  public var body: some View {
    NSLongText(attributedString: text, maxWidth: maxWidth)
      .frame(width: textSize.width, height: textSize.height)
  }

  let text: NSAttributedString
  let maxWidth: CGFloat

  private let textSize: CGSize

}

// MARK: - NSLongText

struct NSLongText: NSViewRepresentable {
  /// The attributed string with syntax highlighting
  let attributedString: NSAttributedString
  let maxWidth: CGFloat

  func makeNSView(context _: Context) -> NSTextView {
    // Create the text storage, layout manager, and text container
    let textStorage = NSTextStorage(attributedString: attributedString)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer()

    // Hook them up
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)

    // Create an NSTextView
    let textView = NSTextView(frame: .zero, textContainer: textContainer)

    // Configure text view
    textView.isEditable = false
    textView.isSelectable = true
    textView.isVerticallyResizable = false
    textView.isHorizontallyResizable = false
    textView.textContainer?.size = LongText.size(for: attributedString, maxWidth: maxWidth)
    textView.textContainer?.widthTracksTextView = false
    textView.backgroundColor = .clear
    return textView
  }

  func updateNSView(_ nsView: NSTextView, context _: Context) {
    nsView.textStorage?.setAttributedString(attributedString)
    nsView.textContainer?.size = LongText.size(for: attributedString, maxWidth: maxWidth)
    nsView.needsLayout = true
    nsView.needsDisplay = true
  }
}

// MARK: - NSFont + @retroactive @unchecked Sendable

extension NSFont: @retroactive @unchecked Sendable { }
