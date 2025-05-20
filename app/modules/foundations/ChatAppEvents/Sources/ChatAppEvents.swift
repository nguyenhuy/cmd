// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventServiceInterface
import ChatFoundation

// MARK: - AddCodeToChatEvent

public struct AddCodeToChatEvent: AppEvent {
  public init(newThread: Bool, chatMode: ChatMode?) {
    self.newThread = newThread
    self.chatMode = chatMode
  }

  public let newThread: Bool
  public let chatMode: ChatMode?
}

// MARK: - NewChatEvent

public struct NewChatEvent: AppEvent {
  public init() { }
}

// MARK: - EditEvent

public struct EditEvent: AppEvent {
  public init() { }
}

// MARK: - GenerateEvent

public struct GenerateEvent: AppEvent {
  public init() { }
}

// MARK: - HideChatEvent

public struct HideChatEvent: AppEvent {
  public init() { }
}
