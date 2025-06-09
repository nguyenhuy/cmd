// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

extension View {
  @inlinable
  nonisolated public func frame(square size: CGFloat) -> some View {
    frame(width: size, height: size)
  }
}
