// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation

import CheckpointServiceInterface

// MARK: - ChatEvent

public enum ChatEventModel: Sendable {
  case message(_ message: ChatMessageContentWithRoleModel)
  case checkpoint(_ checkpoint: Checkpoint)
}
