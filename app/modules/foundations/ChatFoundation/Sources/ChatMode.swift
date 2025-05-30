// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

// MARK: - ChatModes

public enum ChatMode: String, Sendable, Hashable, Equatable, CaseIterable, Identifiable {
  case agent
  case ask

  /// The unique identifier for the chat mode.
  public var id: String {
    switch self {
    case .agent:
      "agentChatMode"
    case .ask:
      "askChatMode"
    }
  }

  /// The display name of the chat mode.
  public var name: String {
    switch self {
    case .agent:
      "Agent"
    case .ask:
      "Ask"
    }
  }

  /// A short description that can be shown in the UI.
  public var description: String {
    switch self {
    case .agent:
      "Plan, search, build anything."
    case .ask:
      "Ask questions about your codebase."
    }
  }

  /// A description of the role, send to the LLM.
  public var roleDescription: String {
    switch self {
    case .agent:
      "You are a highly skilled software engineer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices, but most specifically in iOS and MacOS development (Swift, Xcode, SwiftUI, ObjC etc)"
    case .ask:
      "You are a knowledgeable technical assistant focused on answering questions and providing information about software development, technology, and related topics. You are an expert in iOS and MacOS development (Swift, Xcode, SwiftUI, ObjC etc). You can analyze code, explain concepts, and access external resources. Make sure to answer the user's questions and don't rush to switch to implementing code. Include Mermaid diagrams if they help make your response clearer."
    }
  }

}
