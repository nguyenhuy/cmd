// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
