// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SettingsServiceInterface
import SwiftUI

// MARK: - SettingsView

public struct SettingsView: View {
  public init(viewModel: SettingsViewModel, onDismiss: @MainActor @escaping () -> Void = { }) {
    _viewModel = State(initialValue: viewModel)
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ZStack {
      if currentView == .landing {
        SettingsLandingView(
          onNavigate: { section in
            currentView = section
          },
          onSave: {
            viewModel.save()
          },
          onDismiss: onDismiss)
      }

      if currentView != .landing {
        overlayView
          .transition(.move(edge: .trailing))
      }
    }
    .padding(.horizontal, Constants.horizontalPadding)
    .padding(.vertical, Constants.verticalPadding)
    .background(colorScheme.primaryBackground)
  }

  private enum Constants {
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 16
  }

  @Environment(\.colorScheme) private var colorScheme
  @State private var viewModel: SettingsViewModel
  @State private var currentView = SettingsSection.landing

  private let onDismiss: @MainActor () -> Void

  @ViewBuilder
  private var overlayView: some View {
    VStack(spacing: 0) {
      // Header with back button
      HStack {
        HoveredButton(
          action: {
            currentView = .landing
          },
          onHoverColor: colorScheme.tertiarySystemBackground,
          padding: 6,
          cornerRadius: 8)
        {
          HStack(spacing: 6) {
            Image(systemName: "chevron.left")
              .font(.system(size: 12, weight: .medium))
            Text("Back")
          }
        }

        Spacer()

//        HoveredButton(action: {
//          viewModel.save()
//        },
//                      onHoverColor: colorScheme.secondarySystemBackground) {
//          Text("Save")
//        }
      }

      // Header with icon and title
      HStack(spacing: 8) {
        Image(systemName: currentView.iconName)
          .frame(width: 16, height: 16)
        Text(currentView.title)
          .font(.title2)
          .fontWeight(.medium)
        Spacer()
      }
      .padding(.top, 16)
      .padding(.bottom, 20)

      // Content
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          switch currentView {
          case .providers:
            ProvidersView(providerSettings: $viewModel.providerSettings)

          case .internalSettings:
            InternalSettingsView(
              pointReleaseXcodeExtensionToDebugApp: $viewModel.settings.pointReleaseXcodeExtensionToDebugApp,
              allowAnonymousAnalytics: $viewModel.settings.allowAnonymousAnalytics)

          case .about:
            AboutSettingsView(allowAnonymousAnalytics: $viewModel.settings.allowAnonymousAnalytics)

          case .landing:
            EmptyView()
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

}

// MARK: - SettingsSection

private enum SettingsSection: String, Identifiable, CaseIterable {
  case landing
  case providers
  case internalSettings
  case about

  var id: String { rawValue }

  var title: String {
    switch self {
    case .landing:
      "Settings"
    case .providers:
      "Providers"
    case .internalSettings:
      "Internal Settings"
    case .about:
      "About"
    }
  }

  var iconName: String {
    switch self {
    case .landing:
      "gearshape"
    case .providers:
      "key"
    case .internalSettings:
      "slider.horizontal.3"
    case .about:
      "info.circle"
    }
  }
}

// MARK: - SettingsLandingView

private struct SettingsLandingView: View {
  let onNavigate: (SettingsSection) -> Void
  let onSave: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Back button
      HoveredButton(
        action: {
          onDismiss()
        },
        onHoverColor: colorScheme.tertiarySystemBackground,
        padding: 6,
        cornerRadius: 8)
      {
        HStack(spacing: 6) {
          Image(systemName: "chevron.left")
            .font(.system(size: 12, weight: .medium))
          Text("Back")
        }
      }

      // Header
      HStack {
        Icon(systemName: "gearshape")
          .frame(width: 16, height: 16)

        Text("Settings")
          .font(.title2)
          .fontWeight(.medium)
        Spacer()
      }
      .padding(.vertical, 16)

      // Settings cards
      ScrollView {
        VStack(spacing: 16) {
          SettingsCard(
            section: .providers,
            description: "Manage API keys and setup LLM providers",
            action: onNavigate)

          SettingsCard(
            section: .about,
            description: nil,
            action: onNavigate)

          #if DEBUG
          SettingsCard(
            section: .internalSettings,
            description: "Custom application settings",
            action: onNavigate)
          #endif
        }
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

}

// MARK: - SettingsCard

private struct SettingsCard: View {
  let section: SettingsSection
  let description: String?
  let action: (SettingsSection) -> Void

  var body: some View {
    Button(action: { action(section) }) {
      HStack(spacing: 16) {
        Image(systemName: section.iconName)
          .font(.system(size: 20))
          .frame(width: 32, height: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text(section.title)
            .font(.headline)
            .foregroundColor(.primary)
          if let description {
            Text(description)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.secondary)
      }
      .padding(16)
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity)
  }
}
