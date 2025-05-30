// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import SwiftUI

/// This file contains SwiftUI extensions to detect taps outside of a view.
/// Implementation based on: https://stackoverflow.com/a/72750215/2054629

extension View {
  /// Adds a modifier that detects taps outside the current view and performs an action
  /// - Parameter action: The action to perform when a tap is detected outside the view
  /// - Returns: A view that can detect taps outside the current view
  public func onOutsideTap(_ action: @escaping () -> Void) -> some View {
    background(
      onOutsideTapContent(action))
  }

  /// Creates a transparent overlay that detects taps outside the current view
  /// - Parameter action: The action to perform when a tap is detected outside the view
  /// - Returns: A view that can detect taps outside the current view
  @ViewBuilder
  private func onOutsideTapContent(_ action: @escaping () -> Void) -> some View {
    Color.clear
      .frame(width: (NSScreen.main?.frame.size.width ?? 5000) * 2, height: (NSScreen.main?.frame.size.height ?? 5000) * 2)
      .contentShape(Rectangle())
      .onTapGesture(perform: action)
  }

}
