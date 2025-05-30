// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DependencyFoundation

// MARK: - ToolsPluginDependencyKey

public final class ToolsPluginDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue = ToolsPlugin()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: ToolsPlugin = () as! ToolsPlugin
  #endif
}

extension DependencyValues {
  public var toolsPlugin: ToolsPlugin {
    get { self[ToolsPluginDependencyKey.self] }
    set { self[ToolsPluginDependencyKey.self] = newValue }
  }
}

// MARK: - ToolsPluginProviding

public protocol ToolsPluginProviding {
  var toolsPlugin: ToolsPlugin { get }
}

extension BaseProviding {
  public var toolsPlugin: ToolsPlugin {
    shared {
      ToolsPlugin()
    }
  }
}
