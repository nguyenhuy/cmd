// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import LLMServiceInterface
import SwiftUI

// MARK: - LLMSelectionView

struct LLMSelectionView: View {

  @Binding var selectedModel: LLMModel?

  let availableModels: [LLMModel]

  var filteredModels: [LLMModel] {
    if searchText.isEmpty {
      return availableModels
    }
    return availableModels.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    Button {
      isExpanded.toggle()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
        Text(selectedModel?.displayName ?? "No model configured")
      }
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottomLeading) {
      if isExpanded {
        VStack(spacing: 0) {
          // Search field
          TextField("Search...", text: $searchText)
            .textFieldStyle(.plain)
            .padding(8)

          Divider()

          // Model list
          VStack(spacing: 0) {
            ForEach(filteredModels) { model in
              Button {
                selectedModel = model
                isExpanded = false
                searchText = ""
              } label: {
                HStack {
                  Text(model.displayName)
                  Spacer()
                  if model == selectedModel {
                    Image(systemName: "checkmark")
                  }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                  colorScheme.secondarySystemBackground
                    .opacity(model == selectedModel ? 1 : 0.001))
              }
              .buttonStyle(.plain)

              if model != filteredModels.last {
                Divider()
              }
            }
          }
        }
        .cornerRadius(6)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(colorScheme.primaryBackground)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(colorScheme.textAreaBorderColor, lineWidth: 1)))
        .offset(y: -30)
        .fixedSize(horizontal: true, vertical: false)
        .onOutsideTap {
          isExpanded = false
        }
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  @State private var searchText = ""
  @State private var isExpanded = false
}

// MARK: - Preview

#if DEBUG
@MainActor private let previews: some View = VStack {
  VStack(alignment: .leading) {
    Spacer()
    HStack(alignment: .top) {
      LLMSelectionView(
        selectedModel: .constant(.claudeSonnet),
        availableModels: LLMModel.allCases)
      Divider()
        .frame(height: 10)
      Text("some other text")
      Spacer()
    }
  }
  .frame(width: 300)
  .padding()
  .background(.background)

  LLMSelectionView(
    selectedModel: .constant(.gpt4o),
    availableModels: LLMModel.allCases)
    .frame(width: 300)
    .padding()
    .background(.background)
}

#Preview("Light mode") {
  previews.environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
  previews.environment(\.colorScheme, .dark)
}
#endif
