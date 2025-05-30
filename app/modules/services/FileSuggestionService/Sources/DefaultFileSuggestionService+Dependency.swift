// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import DependencyFoundation
import FileSuggestionServiceInterface
import FoundationInterfaces
import ShellServiceInterface
import XcodeObserverServiceInterface

extension BaseProviding where
  Self: ShellServiceProviding,
  Self: FileManagerProviding
{
  public var fileSuggestionService: FileSuggestionService {
    shared {
      DefaultFileSuggestionService(
        fileManager: fileManager,
        shellService: shellService)
    }
  }
}
