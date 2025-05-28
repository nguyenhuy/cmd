// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SwiftUI

// MARK: - ProvidersView

struct ProvidersView: View {
  @Binding var providerSettings: [ProviderSettings]

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

  @State private var orderedProviders: [APIProvider] = APIProvider.allCases

  @State private var searchText = ""

  private var filteredProviders: [ProviderInfo] {
    let allProviders = orderedProviders.map { provider in
      let existingSettings = providerSettings.first { $0.provider == provider }
      return ProviderInfo(
        provider: provider,
        settings: existingSettings,
        isConnected: existingSettings?.hasValidAPIKey ?? false)
    }

    return searchText.isEmpty
      ? allProviders
      : allProviders.filter {
        $0.provider.rawValue.localizedCaseInsensitiveContains(searchText)
      }
  }

  private func setInitialOrder() {
    orderedProviders = APIProvider.allCases.map { provider in
      let existingSettings = providerSettings.first { $0.provider == provider }
      return (provider, existingSettings?.hasValidAPIKey == true)
    }.sorted { lhs, rhs in
      // Sort: connected first, then alphabetically
      if lhs.1 != rhs.1 {
        return lhs.1 && !rhs.1
      }
      return lhs.0.rawValue < rhs.0.rawValue
    }
    .map(\.0)
  }

  private func updateProviderSettings(for provider: APIProvider, with newSettings: ProviderSettings?) {
    // Remove existing settings for this provider
    providerSettings.removeAll { $0.provider == provider }

    // Add new settings if provided
    if let newSettings {
      providerSettings.append(newSettings)
    }
  }
}

// MARK: - ProviderInfo

private struct ProviderInfo {
  let provider: APIProvider
  let settings: ProviderSettings?
  let isConnected: Bool
}

// MARK: - ProviderCard

private struct ProviderCard: View {
  let provider: APIProvider
  let settings: ProviderSettings?
  let isConnected: Bool
  let onSettingsChanged: (ProviderSettings?) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(provider.rawValue)
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
    switch settings {
    case .anthropic(let anthropicSettings):
      apiKey = anthropicSettings.apiKey
      baseURL = anthropicSettings.baseUrl ?? ""

    case .openAI(let openAISettings):
      apiKey = openAISettings.apiKey
      baseURL = ""

    case .openRouter(let openRouterSettings):
      apiKey = openRouterSettings.apiKey
      baseURL = ""

    case .none:
      apiKey = ""
      baseURL = ""
    }
  }

  private func saveSettings() {
    guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      onSettingsChanged(nil)
      return
    }

    let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

    switch provider {
    case .anthropic:
      let settings = AnthropicProviderSettings(
        apiKey: trimmedAPIKey,
        baseUrl: trimmedBaseURL.isEmpty ? nil : trimmedBaseURL)
      onSettingsChanged(.anthropic(settings))

    case .openAI:
      let settings = OpenAIProviderSettings(apiKey: trimmedAPIKey)
      onSettingsChanged(.openAI(settings))

    case .openRouter:
      let settings = OpenRouterProviderSettings(apiKey: trimmedAPIKey)
      onSettingsChanged(.openRouter(settings))
    }
  }
}

// MARK: - APIProvider Extensions

extension APIProvider {
  var description: String {
    switch self {
    case .anthropic:
      "Claude models"
    case .openAI:
      "GPT models"
    case .openRouter:
      "Multiple model providers"
    }
  }

  var supportsBaseURL: Bool {
    switch self {
    case .anthropic:
      true
    case .openAI, .openRouter:
      false
    }
  }
}

// MARK: - ProviderSettings Extensions

extension ProviderSettings {
  var apiKey: String {
    switch self {
    case .anthropic(let settings):
      settings.apiKey
    case .openAI(let settings):
      settings.apiKey
    case .openRouter(let settings):
      settings.apiKey
    }
  }

  var hasValidAPIKey: Bool {
    !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
