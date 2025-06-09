// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Down
import SwiftUI

// MARK: - MarkdownStyle

class MarkdownStyle: DownStyle {

  init(colorScheme: ColorScheme) {
    super.init()

    baseFont = Font.systemFont(ofSize: 14, weight: .regular)
    baseFontColor = colorScheme.primaryForeground.nsColor

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacingBefore = 0
    paragraphStyle.paragraphSpacing = 0
    paragraphStyle.lineSpacing = 3
    baseParagraphStyle = paragraphStyle

    h1Size = 18
    h2Size = 16
    h3Size = 15
    codeFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    codeColor = .controlAccentColor
    quoteColor = .secondaryLabelColor
  }

  override var h1Attributes: DownStyle.Attributes {
    super.h1Attributes.merging([
      .font: baseFont.withSize(h1Size),
    ])
  }

  override var h2Attributes: DownStyle.Attributes {
    super.h2Attributes.merging([
      .font: baseFont.withSize(h2Size),
    ])
  }

  override var h3Attributes: DownStyle.Attributes {
    super.h3Attributes.merging([
      .font: baseFont.withSize(h3Size),
    ])
  }
}

extension DownStyle.Attributes {
  func merging(_ other: DownStyle.Attributes) -> DownStyle.Attributes {
    merging(other, uniquingKeysWith: { $1 })
  }
}
