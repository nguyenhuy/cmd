// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

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
