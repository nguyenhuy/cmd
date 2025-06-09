// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

extension View {
  /// Adds a rounded corner with a border to the view.
  public func roundedCornerWithBorder(lineWidth: CGFloat = 1, borderColor: Color, radius: CGFloat) -> some View {
    clipShape(RoundedCorner(radius: radius))
      .overlay(
        RoundedCorner(radius: radius)
          .stroke(borderColor, lineWidth: lineWidth))
  }

  /// Adds a rounded corner to the view.
  public func roundedCorner(radius: CGFloat) -> some View {
    clipShape(RoundedCorner(radius: radius))
  }

  /// Adds a rounded corner to the view.
  public func roundedCorner(radius: CGFloat, corners: Corners) -> some View {
    clipShape(RoundedCornerShape(radius: radius, corners: corners))
  }
}

// MARK: - RoundedCorner

private struct RoundedCorner: Shape {
  var radius = CGFloat.infinity
  func path(in rect: CGRect) -> Path {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    return Path(path.cgPath)
  }
}

// MARK: - Corners

/// An OptionSet to specify which corners should be rounded.
public struct Corners: OptionSet, Sendable {
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  public static let topLeft = Corners(rawValue: 1 << 0)
  public static let topRight = Corners(rawValue: 1 << 1)
  public static let bottomLeft = Corners(rawValue: 1 << 2)
  public static let bottomRight = Corners(rawValue: 1 << 3)
}

// MARK: - RoundedCornerShape

/// A Shape that rounds only the specified corners.
public struct RoundedCornerShape: Shape {
  public init(radius: CGFloat, corners: Corners) {
    self.radius = radius
    self.corners = corners
  }

  public func path(in rect: CGRect) -> Path {
    var path = Path()

    // Helper for corner radius if in `corners`, or 0 if not
    func cornerRadius(_ corner: Corners) -> CGFloat {
      corners.contains(corner) ? radius : 0
    }

    let tl = cornerRadius(.topLeft)
    let tr = cornerRadius(.topRight)
    let bl = cornerRadius(.bottomLeft)
    let br = cornerRadius(.bottomRight)

    // Start top-left
    path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))

    // Top edge, then top-right corner
    path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
    if tr > 0 {
      path.addArc(
        center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
        radius: tr,
        startAngle: .degrees(270),
        endAngle: .degrees(0),
        clockwise: false)
    }

    // Right edge, then bottom-right corner
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
    if br > 0 {
      path.addArc(
        center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
        radius: br,
        startAngle: .degrees(0),
        endAngle: .degrees(90),
        clockwise: false)
    }

    // Bottom edge, then bottom-left corner
    path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
    if bl > 0 {
      path.addArc(
        center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
        radius: bl,
        startAngle: .degrees(90),
        endAngle: .degrees(180),
        clockwise: false)
    }

    // Left edge, then top-left corner
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
    if tl > 0 {
      path.addArc(
        center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
        radius: tl,
        startAngle: .degrees(180),
        endAngle: .degrees(270),
        clockwise: false)
    }

    return path
  }

  var radius: CGFloat
  var corners: Corners

}
