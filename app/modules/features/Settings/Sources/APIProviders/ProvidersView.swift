// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SwiftUI

// MARK: - ProvidersView

struct ProvidersView: View {
  @State private var newProviderSettings: ProviderSettings?
  @Binding var providerSettings: [ProviderSettings]

  var body: some View {
    if !providersNotSetup.isEmpty {
      newProvider
    }

    ForEach(providerSettings.indices, id: \.self) { idx in

      VStack(alignment: .leading, spacing: 0) {
        Divider()
          .padding(.bottom, 10)
        HStack(alignment: .top, spacing: 3) {
          IconButton(
            action: {
              providerSettings.remove(at: idx)
            },
            systemName: "xmark",
            padding: 2)
            .frame(width: 14, height: 14)
            .padding(.top, 3)

          VStack(alignment: .leading, spacing: 0) {
            Text(providerSettings[idx].provider.rawValue)
              .font(.title2)
            providerView(for: Binding<ProviderSettings>(
              get: { providerSettings[idx] },
              set: { newValue in
                providerSettings[idx] = newValue
              }))
          }
        }
      }
    }
  }

  @ViewBuilder
  private func providerView(for providerSetting: Binding<ProviderSettings>) -> some View {
    switch providerSetting.wrappedValue {
    case .anthropic(let settings):
      AnthropicSettingsView(settings: Binding<AnthropicProviderSettings>(
        get: { settings },
        set: { newValue in providerSetting.wrappedValue = .anthropic(newValue) }))

    case .openAI(let settings):
      OpenAISettingsView(settings: Binding<OpenAIProviderSettings>(
        get: { settings },
        set: { newValue in providerSetting.wrappedValue = .openAI(newValue) }))
    }
  }

  @ViewBuilder
  private var newProvider: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("New API Provider")
          .font(.headline)
      }
      .padding(.bottom, 8)

      Menu {
        ForEach(providersNotSetup, id: \.self) { provider in
          Button(action: {
            switch provider {
            case .anthropic:
              newProviderSettings = .anthropic(AnthropicProviderSettings(apiKey: ""))
            case .openAI:
              newProviderSettings = .openAI(OpenAIProviderSettings(apiKey: ""))
            }
          }) {
            HStack {
              Text(provider.rawValue)
              Spacer()
              if provider == newProviderSettings?.provider {
                Image(systemName: "checkmark")
              }
            }
          }
        }
      } label: {
        Text(newProviderSettings?.provider.rawValue ?? "")
      }
      if newProviderSettings != nil {
        providerView(for: $newProviderSettings.unwrapped)

        RoundedButton(
          padding: EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5),
          action: {
            if let newProviderSettings {
              providerSettings.append(newProviderSettings)
              self.newProviderSettings = nil
            }
          }, label: {
            Text("Add")
          })
      }
    }
    .padding()
  }

  private var providersNotSetup: [APIProvider] {
    APIProvider.allCases.filter { !providerSettings.map(\.provider).contains($0) }
  }
}

extension Binding where Value == ProviderSettings? {
  var unwrapped: Binding<ProviderSettings> {
    Binding<ProviderSettings>(
      get: { wrappedValue ?? .anthropic(AnthropicProviderSettings(apiKey: "")) },
      set: { wrappedValue = $0 })
  }
}
