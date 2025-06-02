// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppKit
import SwiftUI

// MARK: - Input

public struct Input {
  let bringWindowToFront: @MainActor () -> Void
  let onDone: @MainActor () -> Void
  let createLLMProvidersView: @MainActor (@MainActor @escaping () -> Void) -> AnyView

  public init(
    bringWindowToFront: @MainActor @escaping () -> Void,
    onDone: @MainActor @escaping () -> Void,
    createLLMProvidersView: @MainActor @escaping (@MainActor @escaping () -> Void) -> AnyView)
  {
    self.bringWindowToFront = bringWindowToFront
    self.onDone = onDone
    self.createLLMProvidersView = createLLMProvidersView
  }
}

// MARK: - OnboardingFeatureBuilder

public enum OnboardingFeatureBuilder {
  @MainActor
  public static func build(_ input: Input) -> AnyView {
    let viewModel = OnboardingViewModel(
      bringWindowToFront: input.bringWindowToFront,
      onDone: input.onDone)
    return AnyView(OnboardingView(viewModel: viewModel, createLLMProvidersView: input.createLLMProvidersView))
  }

}
