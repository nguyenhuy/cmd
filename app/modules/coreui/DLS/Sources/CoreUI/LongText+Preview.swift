// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

#if DEBUG
#Preview {
  VStack {
    LongText("This is a long text view\n\nOver several lines")
      .border(.red)
  }
  .frame(width: 400, height: 800)
  .padding()
}
#endif
