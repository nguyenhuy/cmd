// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies
import DLS
import PermissionsServiceInterface
import SwiftUI

// MARK: - OnboardingView

#if DEBUG

func createMockPermissionService() -> MockPermissionsService {
  let service = MockPermissionsService()
  service.onRequestAccessibilityPermission = {
    Task {
      try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate a delay
      await service.set(permission: .accessibility, granted: true)
    }
  }
  service.onRequestXcodeExtensionPermission = {
    Task {
      try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate a delay
      await service.set(permission: .xcodeExtension, granted: true)
    }
  }
  return service
}

struct ProvidersView: View {
  let onDone: @MainActor () -> Void

  var body: some View {
    VStack {
      Text("Providers View")
      HoveredButton(
        action: onDone,
        content: {
          Text("Done")
        })
    }
  }
}

extension OnboardingView {
  init(
    createLLMProvidersView: @Sendable @escaping (@MainActor @escaping () -> Void) -> AnyView)
  {
    self.init(
      viewModel: OnboardingViewModel(),
      createLLMProvidersView: createLLMProvidersView)
  }
}

#Preview("OnboardingView") {
  withDependencies {
    $0.permissionsService = createMockPermissionService()
  } operation: {
    OnboardingView(createLLMProvidersView: { onDone in
      AnyView(ProvidersView(onDone: onDone))
    })
  }
}

#endif
