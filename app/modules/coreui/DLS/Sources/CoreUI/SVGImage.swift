// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - SVGImage

/// A view that displays an SVG image.
public struct SVGImage: View {
  public init(_ asset: URL) {
    image = try? SVGImageLoader.svg(atPath: asset.path)
  }

  private let image: NSImage?
  public var body: some View {
    if let image {
      Image(nsImage: image)
        .renderingMode(.template)
        .resizable()
        .interpolation(.none)
        .scaledToFit()
    } else {
      Icon(systemName: "questionmark.circle")
    }
  }
}

// MARK: - SVGImageLoader

@MainActor
public class SVGImageLoader {
  public static func svg(atPath: String) throws -> NSImage {
    if let cachedImage = cachedImages[atPath] {
      return cachedImage
    }
    guard
      let svgData = FileManager.default.contents(atPath: atPath)
    else {
      throw URLError(.badURL)
    }
    guard let image = NSImage(data: svgData) else {
      throw URLError(.cannotDecodeRawData)
    }
    cachedImages[atPath] = image
    return image
  }

  @MainActor private static var cachedImages = [String: NSImage]()

}
