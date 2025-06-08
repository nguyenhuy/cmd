// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import ToolFoundation

extension EditFilesTool.Use {
  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let callingTool = try container.decode(EditFilesTool.self, forKey: .callingTool)
    let toolUseId = try container.decode(String.self, forKey: .toolUseId)
    let inputData = try container.decode(Data.self, forKey: .inputData)
    let isInputComplete = try container.decode(Bool.self, forKey: .isInputComplete)
    let context = try container.decode(ToolExecutionContext.self, forKey: .context)
    let statusValue = try container.decode(ToolUseExecutionStatus<Output>.self, forKey: .status)

    try self.init(
      callingTool: callingTool,
      toolUseId: toolUseId,
      input: inputData,
      isInputComplete: isInputComplete,
      context: context,
      initialStatus: statusValue)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(callingTool, forKey: .callingTool)
    try container.encode(toolUseId, forKey: .toolUseId)

    // Encode the input as Data
    let inputData = try JSONEncoder().encode(input)
    try container.encode(inputData, forKey: .inputData)

    try container.encode(isInputComplete.value, forKey: .isInputComplete)
    try container.encode(context, forKey: .context)
    try container.encode(status.value, forKey: .status)
  }

  private enum CodingKeys: String, CodingKey {
    case callingTool
    case toolUseId
    case inputData
    case isInputComplete
    case context
    case status
  }
}
