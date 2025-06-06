// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

import LLMFoundation
// MARK: - ModelsView+Previews

#if DEBUG
#Preview {
  ModelsView(
    availableModels: LLMModel.allCases,
    availableProviders: LLMProvider.allCases,
    providerForModels: .constant([:]),
    inactiveModels: .constant([]),
    reasoningModels: .constant([:]))
    .frame(width: 600, height: 800)
}

#endif
