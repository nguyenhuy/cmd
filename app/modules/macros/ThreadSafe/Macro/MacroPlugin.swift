// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ThreadSafePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ThreadSafeMacro.self,
    ThreadSafeInitializerMacro.self,
    ThreadSafePropertyMacro.self,
  ]
}
