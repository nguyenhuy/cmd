// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SettingsServiceInterface
import SwiftUI

// MARK: - SettingsView

public struct SettingsView: View {
  public init(viewModel: SettingsViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  public var body: some View {
    VStack {
      HStack {
        Text("Settings")
        Spacer()
        RoundedButton(action: {
          viewModel.save()
        }, label: {
          Text("Save")
        })
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 5)

      HStack {
        List(selection: $selectedSection) {
          NavigationLink(value: SettingsSection.general) {
            Label("General", systemImage: "gear")
          }

          NavigationLink(value: SettingsSection.providers) {
            Label("Providers", systemImage: "app.connected.to.app.below.fill")
          }
        }
        .frame(width: 130)

        ScrollView {
          VStack(alignment: .leading, spacing: 30) {
            switch selectedSection {
            case .providers:
              ProvidersView(providerSettings: $viewModel.providerSettings)
            case .general, nil:
              GeneralSettingsView(pointReleaseXcodeExtensionToDebugApp: $viewModel.settings.pointReleaseXcodeExtensionToDebugApp)
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  @State private var viewModel: SettingsViewModel
  @State private var selectedSection: SettingsSection? = .general

  @Environment(\.colorScheme) private var colorScheme

}

// MARK: - SettingsSection

private enum SettingsSection: String, Identifiable, CaseIterable {
  case general
  case providers

  var id: String { rawValue }
}
