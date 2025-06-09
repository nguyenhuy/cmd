// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

extension View {
  @inlinable
  nonisolated public func frame(square size: CGFloat) -> some View {
    frame(width: size, height: size)
  }
}
