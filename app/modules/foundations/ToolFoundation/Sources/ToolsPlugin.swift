// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ChatFoundation
import ThreadSafe

@ThreadSafe
public final class ToolsPlugin: Sendable {

  #if DEBUG
  public init() { }
  #else
  init() { }
  #endif

  public var tools: [any Tool] {
    Array(registry.values)
  }

  public func tools(for mode: ChatMode) -> [any Tool] {
    Array(registry.values).filter { $0.isAvailable(in: mode) }
  }

  public func plugIn(tool: any Tool) {
    registry[tool.name] = tool
  }

  public func tool(named name: String) -> (any Tool)? {
    registry[name]
  }

  private var registry = [String: any Tool]()

}
