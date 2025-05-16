// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import LLMServiceInterface
import SwiftUI

#if DEBUG
#Preview {
  VStack {
    ChatInputView(
      inputViewModel: .init(availableModels: LLMModel.allCases),
      isStreamingResponse: .constant(false),
      didTapCancel: { },
      didSend: { })
    Divider()
    ChatInputView(
      inputViewModel: .init(availableModels: LLMModel.allCases),
      isStreamingResponse: .constant(true),
      didTapCancel: { },
      didSend: { })
  }
}
#endif
