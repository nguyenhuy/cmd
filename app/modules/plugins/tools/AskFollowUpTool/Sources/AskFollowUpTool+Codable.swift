// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import Foundation
import ToolFoundation

extension AskFollowUpTool.Use {
  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let callingTool = try container.decode(AskFollowUpTool.self, forKey: .callingTool)
    let toolUseId = try container.decode(String.self, forKey: .toolUseId)
    let input = try container.decode(Input.self, forKey: .input)
    let statusValue = try container.decode(ToolUseExecutionStatus<Output>.self, forKey: .status)

    self.init(callingTool: callingTool, toolUseId: toolUseId, input: input, initialStatus: statusValue)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(callingTool, forKey: .callingTool)
    try container.encode(toolUseId, forKey: .toolUseId)
    try container.encode(input, forKey: .input)
    try container.encode(status.value, forKey: .status)
  }

  private enum CodingKeys: String, CodingKey {
    case callingTool
    case toolUseId
    case input
    case status
  }
}
