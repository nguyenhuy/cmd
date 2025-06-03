// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DLS
import SettingsServiceInterface
import SwiftUI

// MARK: - CustomInstructionsView

struct CustomInstructionsView: View {
  
  @Binding var customInstructions: SettingsServiceInterface.Settings.CustomInstructions
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        askModeView
        Divider()
        agentModeView
        InformationCard(
          title: "Tips for Custom Instructions",
          tips: [
            "Keep instructions concise and specific to your needs",
            "Custom instructions are inserted into the default system prompt",
            "Use clear, actionable language rather than vague descriptions",
          ]
        )
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.1))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        Spacer(minLength: 20)
      }
    }
  }
  
  private var askModeView: some View {
    CustomInstructionSection(
      text: $customInstructions.agentMode,
      iconName: "bubble",
      title: "Ask Mode",
      subtitle: "Provide extra instructions for Ask Mode.")
  }
  
  private var agentModeView: some View {
    CustomInstructionSection(
      text: $customInstructions.agentMode,
      iconName: "infinity",
      title: "Agent Mode",
      subtitle: "Provide extra instructions for Agent Mode.")
  }
}

struct CustomInstructionSection: View {
  
  let iconName: String
  let title: String
  let subtitle: String
  let minHeight: CGFloat
  let maxHeight: CGFloat
  let fontSize: CGFloat
  @Binding var text: String
  
  init(
    text: Binding<String>,
    iconName: String,
    title: String,
    subtitle: String,
    minHeight: CGFloat = 100,
    maxHeight: CGFloat = 200,
    fontSize: CGFloat = 13)
  {
    _text = text
    self.iconName = iconName
    self.title = title
    self.subtitle = subtitle
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.fontSize = fontSize
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Icon(systemName: iconName)
          .frame(width: 16, height: 16)
        Text(title)
          .font(.headline)
      }
      .foregroundColor(.primary)
      
      Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
      TextEditor(text: $text)
        .font(.system(size: fontSize))
        .scrollContentBackground(.hidden)
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
  }
}

struct InformationCard: View {
  
  let iconName: String
  let title: String
  let tips: [String]
  let iconColor: Color
  
  init(
    iconName: String = "info.circle",
    title: String,
    tips: [String],
    iconColor: Color = .blue
  ) {
    self.iconName = iconName
    self.title = title
    self.tips = tips
    self.iconColor = iconColor
  }
  
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 14))
        .foregroundColor(iconColor)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
        
        ForEach(tips, id: \.self) { tip in
          Text("• \(tip)")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
    }
  }
}

// MARK: - Preview

#Preview {
  CustomInstructionsView(
    customInstructions: .constant(
      SettingsServiceInterface.Settings.CustomInstructions(
        askModePrompt: "Focus on providing clear and concise answers",
        agentModePrompt: "Be proactive in suggesting improvements"
      )
    )
  )
  .frame(width: 600, height: 500)
  .padding()
}
