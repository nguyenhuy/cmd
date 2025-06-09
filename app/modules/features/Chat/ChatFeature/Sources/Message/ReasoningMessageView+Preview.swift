// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

#if DEBUG
#Preview("ReasoningMessageView (streaming)", traits: .sizeThatFitsLayout) {
  ReasoningMessageView(
    reasoning: .init(deltas: ["Let me", " take a step back"], isStreaming: true))
    .padding(5)
    .frame(minWidth: 400, alignment: .leading)
}

#Preview("ReasoningMessageView (streamed)", traits: .sizeThatFitsLayout) {
  ReasoningMessageView(
    reasoning: .init(deltas: ["Let me", " take a step back"], isStreaming: false))
    .padding(5)
    .frame(minWidth: 400, minHeight: 500, alignment: .leading)
}

#endif
