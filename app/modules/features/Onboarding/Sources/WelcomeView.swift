// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import DLS
import SwiftUI

// MARK: - WelcomeView

struct WelcomeView: View {
  let onGetStarted: () -> Void

  var body: some View {
    VStack(spacing: 40) {
      VStack(spacing: 24) {
        // App icon
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.blue)
          .frame(width: 80, height: 80)
          .overlay(
            AppLogo()
              .tint(.white)
              .frame(square: 60)
              .foregroundColor(colorScheme.primaryForeground))

        VStack(spacing: 16) {
          Text("Welcome to ")
            .font(.largeTitle)
            .fontWeight(.medium)
            .foregroundColor(colorScheme.primaryForeground)
            + Text("cmd")
            .font(.largeTitle)
            .fontWeight(.medium)
            .foregroundColor(.blue)

          Text(
            "Your coding assistant for Xcode. Enhance your development workflow with AI-powered code suggestions.  Let agents automate the busy work so you can focus on what matters most.\n\nIt's all open source and local. No need to trust the middle man: your requests go directly to the LLM provider of your choice.")
            .font(.body)
            .foregroundColor(colorScheme.secondaryForeground)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: OnboardingView.Constants.maxTextWidth)
        }
      }

      HStack(spacing: 24) {
        FeatureCard(
          icon: "sparkles",
          title: "AI-Powered",
          description: "Intelligent code suggestions and automomous edits powered by state-of-the-art language models.",
          color: .blue)

        FeatureCard(
          icon: "lock.open",
          title: "Open Source",
          description: "Fully open source and transparent. Contribute to the future of iOS & MacOS development.",
          color: .green)

        FeatureCard(
          icon: "bolt",
          title: "Xcode Native",
          description: "Seamlessly integrated into your Xcode workflow. No need to use another IDE.",
          color: .purple)

        FeatureCard(
          icon: "shield",
          title: "Local development",
          description: "**cmd** runs locally on your computer. No intermediary services, no additional third parties to trust.",
          color: .purple)
      }

      HoveredButton(
        action: onGetStarted,
        onHoverColor: .accentColor.opacity(0.8),
        backgroundColor: .accentColor,
        padding: 16,
        cornerRadius: 12)
      {
        Text("Get Started")
          .font(.headline)
          .foregroundColor(.white)
          .lineLimit(1)
      }
    }
  }

  @Environment(\.colorScheme) private var colorScheme

}

// MARK: - FeatureCard

private struct FeatureCard: View {
  let icon: String
  let title: String
  let description: String
  let color: Color

  var body: some View {
    VStack(spacing: 16) {
      Icon(systemName: icon).frame(width: 24, height: 24)

      VStack(spacing: 8) {
        Text(title)
          .font(.headline)
          .foregroundColor(colorScheme.primaryForeground)

        Text(.init(description))
          .font(.body)
          .foregroundColor(colorScheme.secondaryForeground)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .padding(24)
    .frame(width: 200)
    .background(colorScheme.secondarySystemBackground)
    .cornerRadius(16)
  }

  @Environment(\.colorScheme) private var colorScheme

}

#if DEBUG

#Preview("WelcomeView") {
  WelcomeView(onGetStarted: { })
}
#endif
