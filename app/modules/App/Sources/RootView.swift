// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Chat
import Combine
import Dependencies
import DLS
import Observation
import PermissionsServiceInterface
import SettingsFeature
import SwiftUI

// MARK: - RootViewState

@Observable
final class RootViewState {

  init() {
    let permissions = permissionsService.status(for: .accessibility)
    isAccessibilityPermissionGranted = permissions.currentValue == true

    permissions.sink { [weak self] status in
      self?.isAccessibilityPermissionGranted = status == true
    }.store(in: &cancellables)
  }

  static var initial: RootViewState {
    .init()
  }

  var isAccessibilityPermissionGranted: Bool?

  @Dependency(\.permissionsService) @ObservationIgnored private var permissionsService

  private var cancellables = Set<AnyCancellable>()
}

// MARK: - RootView

struct RootView: View {

  init(state: RootViewState? = nil) {
    self.state = state ?? .init()
  }

  var body: some View {
    mainView
      .background(colorScheme.primaryBackground)
  }

  @Environment(\.colorScheme) private var colorScheme

  @State private var state: RootViewState

  @ViewBuilder
  private var mainView: some View {
    if state.isAccessibilityPermissionGranted == nil {
      VStack {
        Image(systemName: "globe")
          .imageScale(.large)
          .foregroundStyle(.tint)
        Text("..")
      }
      .padding()
    } else if state.isAccessibilityPermissionGranted == true {
      ChatView(
        viewModel: ChatViewModel(),
        SettingsView: {
          AnyView(SettingsView(viewModel: SettingsViewModel()))
        })
    } else {
      SetupView()
    }
  }

}

#if DEBUG
#Preview {
  let _ = prepareDependencies {
    $0.permissionsService = MockPermissionsService()
  }

  RootView()
}
#endif
