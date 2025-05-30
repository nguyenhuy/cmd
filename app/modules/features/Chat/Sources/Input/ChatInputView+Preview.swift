// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMFoundation
import SwiftUI

#if DEBUG
#Preview {
  VStack {
    ChatInputView(
      inputViewModel: ChatInputViewModel(activeModels: LLMModel.allCases, mode: .ask),
      isStreamingResponse: .constant(false),
      didTapCancel: { },
      didSend: { })
    Divider()
    ChatInputView(
      inputViewModel: ChatInputViewModel(activeModels: LLMModel.allCases, mode: .agent),
      isStreamingResponse: .constant(false),
      didTapCancel: { },
      didSend: { })
    Divider()
    ChatInputView(
      inputViewModel: .init(activeModels: LLMModel.allCases),
      isStreamingResponse: .constant(true),
      didTapCancel: { },
      didSend: { })
  }
}
#endif
