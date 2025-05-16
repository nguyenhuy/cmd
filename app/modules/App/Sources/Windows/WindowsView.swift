// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import Foundation
import Observation

@MainActor
final class WindowsView {

  @MainActor
  init(viewModel: WindowsViewModel) {
    self.viewModel = viewModel
    state = viewModel.state

    // handle initial state
    update(
      to: viewModel.state,
      from: .init(
        isSidePanelVisible: false))
    startObservations(of: viewModel)
  }

  @MainActor var state: WindowsViewModel.State {
    didSet {
      update(to: state, from: oldValue)
    }
  }

  func showSidePanel() {
    if sidePanel == nil {
      sidePanel = SidePanel(windowsViewModel: viewModel)
    }

    sidePanel?.show()
    sidePanel?.orderFrontRegardless()
  }

  func hideSidePanel() {
    sidePanel?.hide()
  }

  private let viewModel: WindowsViewModel

  private var sidePanel: SidePanel?

  private func update(to newState: WindowsViewModel.State, from oldState: WindowsViewModel.State) {
    if newState.isSidePanelVisible != oldState.isSidePanelVisible {
      if newState.isSidePanelVisible {
        showSidePanel()
      } else {
        hideSidePanel()
      }
    }
  }

  @MainActor
  private func startObservations(of viewModel: WindowsViewModel) {
    withObservationTracking({
      _ = viewModel.state
    }, onChange: {
      Task { @MainActor [weak self] in
        guard let self, viewModel === self.viewModel else { return }
        state = viewModel.state
        startObservations(of: viewModel)
      }
    })
  }

}
