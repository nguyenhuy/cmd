// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import SwiftUI

// MARK: - LongText

/// Similar to `SwiftUI.Text`, but uses an NSTextView that is much more performant,
/// especially over long texts that will freeze in a `Text`.
public struct LongText: View {

  public init(_ text: NSAttributedString) {
    self.init(text, needColoring: false)
  }

  private init(_ text: NSAttributedString, needColoring: Bool) {
    self.text = text
    self.needColoring = needColoring
  }

  public init(_ text: AttributedString) {
    self.init(NSAttributedString(text), needColoring: false)
  }

  public init(_ text: String, font: NSFont = .body) {
    let attrString = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
    let range = NSRange(location: 0, length: attrString.length)
    attrString.addAttribute(.font, value: font, range: range)

    self.init(attrString, needColoring: true)
  }

  public var body: some View {
    InnerLongText(attributedTextWithFont)
  }

  let text: NSAttributedString
  let needColoring: Bool

  static func size(for text: NSAttributedString) -> CGSize {
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    let textStorage = NSTextStorage()

    // Hook up the text system objects
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)

    textStorage.setAttributedString(text)
    textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
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

  public init(_ text: NSAttributedString) {
    self.text = text
    textSize = Self.size(for: text)
  }

  public var body: some View {
    NSLongText(attributedString: text)
      .frame(width: textSize.width, height: textSize.height)
  }

  let text: NSAttributedString

  static func size(for text: NSAttributedString) -> CGSize {
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    let textStorage = NSTextStorage()

    // Hook up the text system objects
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)

    textStorage.setAttributedString(text)
    textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
    layoutManager.glyphRange(for: textContainer)
    let usedRect = layoutManager.usedRect(for: textContainer)
    return usedRect.integral.size
  }

  private let textSize: CGSize

}

// MARK: - NSLongText

struct NSLongText: NSViewRepresentable {
  /// The attributed string with syntax highlighting
  let attributedString: NSAttributedString

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
    textView.textContainer?.size = LongText.size(for: attributedString)
    textView.textContainer?.widthTracksTextView = false
    textView.backgroundColor = .clear
    return textView
  }

  func updateNSView(_ nsView: NSTextView, context _: Context) {
    nsView.textStorage?.setAttributedString(attributedString)
    nsView.textContainer?.size = LongText.size(for: attributedString)
    nsView.needsLayout = true
    nsView.needsDisplay = true
  }
}

// MARK: - NSFont + @retroactive @unchecked Sendable

extension NSFont: @retroactive @unchecked Sendable { }
