// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import LLMFoundation
import SettingsServiceInterface
import SwiftUI

// MARK: - ProvidersView

struct ProvidersView: View {
  @Binding var providerSettings: AllLLMProviderSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Search bar
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
          .frame(width: 16, height: 16)
        TextField("Search providers...", text: $searchText)
          .textFieldStyle(.plain)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)
      .padding(.bottom, 20)

      // Provider cards
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(filteredProviders, id: \.provider) { providerInfo in
            ProviderCard(
              provider: providerInfo.provider,
              settings: providerInfo.settings,
              isConnected: providerInfo.isConnected,
              onSettingsChanged: { newSettings in
                updateProviderSettings(for: providerInfo.provider, with: newSettings)
              })
          }
        }
        .padding(.bottom, 20)
      }
    }
    .onAppear {
      setInitialOrder()
    }
  }

  @State private var orderedProviders: [LLMProvider] = LLMProvider.allCases

  @State private var searchText = ""

  private var filteredProviders: [ProviderInfo] {
    let allProviders = orderedProviders.map { provider in
      let existingSettings = providerSettings[provider]
      return ProviderInfo(
        provider: provider,
        settings: existingSettings,
        isConnected: existingSettings?.hasValidAPIKey ?? false)
    }

    return searchText.isEmpty
      ? allProviders
      : allProviders.filter {
        $0.provider.name.localizedCaseInsensitiveContains(searchText)
      }
  }

  private func setInitialOrder() {
    orderedProviders = LLMProvider.allCases.map { provider in
      let existingSettings = providerSettings[provider]
      return (provider, existingSettings?.hasValidAPIKey == true)
    }.sorted { lhs, rhs in
      // Sort: connected first, then alphabetically
      if lhs.1 != rhs.1 {
        return lhs.1 && !rhs.1
      }
      return lhs.0.name < rhs.0.name
    }
    .map(\.0)
  }

  private func updateProviderSettings(for provider: LLMProvider, with newSettings: LLMProviderSettings?) {
    // Add new settings if provided
    if let newSettings {
      let createdOrder = newSettings.createdOrder == -1 ? providerSettings.nextCreatedOrder : newSettings.createdOrder
      providerSettings[provider] = .init(apiKey: newSettings.apiKey, baseUrl: newSettings.baseUrl, createdOrder: createdOrder)
    } else {
      // Remove existing settings for this provider
      providerSettings.removeValue(forKey: provider)
    }
  }
}

// MARK: - ProviderInfo

private struct ProviderInfo {
  let provider: LLMProvider
  let settings: LLMProviderSettings?
  let isConnected: Bool
}

// MARK: - ProviderCard

private struct ProviderCard: View {
  let provider: LLMProvider
  let settings: LLMProviderSettings?
  let isConnected: Bool
  let onSettingsChanged: (LLMProviderSettings?) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(provider.name)
              .font(.title2)
              .fontWeight(.medium)
            Spacer()
            Text(isConnected ? "Connected" : "Not connected")
              .font(.subheadline)
              .foregroundColor(isConnected ? colorScheme.addedLineDiffText : .secondary)
          }

          Text(provider.description)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }

      // API Key section
      VStack(alignment: .leading, spacing: 8) {
        Text("API Key")
          .font(.subheadline)
          .fontWeight(.medium)

        HStack {
          if showAPIKey {
            TextField("Enter API key...", text: $apiKey)
              .textFieldStyle(.plain)
          } else {
            SecureField("Enter API key...", text: $apiKey)
              .textFieldStyle(.plain)
          }

          if !apiKey.isEmpty {
            Button(action: { showAPIKey.toggle() }) {
              Image(systemName: showAPIKey ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .roundedCornerWithBorder(borderColor: Color.gray.opacity(0.3), radius: 6)

        Text("API keys are stored securely in the keychain")
          .font(.footnote)
          .foregroundColor(.secondary)
      }

      // Base URL section (for providers that support it)
      if provider.supportsBaseURL {
        VStack(alignment: .leading, spacing: 8) {
          Text("Base URL (Optional)")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Enter base URL...", text: $baseURL)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .roundedCornerWithBorder(borderColor: Color.gray.opacity(0.3), radius: 6)
        }
      }
    }
    .padding(16)
    .background(Color(NSColor.controlBackgroundColor))
    .roundedCornerWithBorder(borderColor: Color.gray.opacity(0.2), radius: 12)
    .onAppear {
      loadCurrentSettings()
    }
    .onChange(of: apiKey) { _, _ in
      saveSettings()
    }
    .onChange(of: baseURL) { _, _ in
      if provider.supportsBaseURL {
        saveSettings()
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  @State private var apiKey = ""
  @State private var baseURL = ""
  @State private var showAPIKey = false

  private func loadCurrentSettings() {
    apiKey = settings?.apiKey ?? ""
    baseURL = settings?.baseUrl ?? ""
  }

  private func saveSettings() {
    guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      onSettingsChanged(nil)
      return
    }

    let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

    let settings = LLMProviderSettings(
      apiKey: trimmedAPIKey,
      baseUrl: trimmedBaseURL.isEmpty ? nil : trimmedBaseURL,
      createdOrder: -1)
    onSettingsChanged(settings)
  }
}

// MARK: - APIProvider Extensions

extension LLMProvider {
  var description: String {
    switch self {
    case .anthropic:
      "Claude models"
    case .openAI:
      "GPT models"
    case .openRouter:
      "Multiple model providers"
    default:
      "Unknown provider"
    }
  }

  var supportsBaseURL: Bool {
    switch self {
    case .anthropic:
      true
    case .openAI, .openRouter:
      false
    default:
      false
    }
  }
}

// MARK: - ProviderSettings Extensions

extension LLMProviderSettings {

  var hasValidAPIKey: Bool {
    !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
