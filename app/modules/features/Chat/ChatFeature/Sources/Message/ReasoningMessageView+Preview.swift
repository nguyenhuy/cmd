// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

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
