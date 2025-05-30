// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import DependencyFoundation
import XcodeObserverServiceInterface

extension BaseProviding where Self: IsHostAppActiveProviding, Self: XcodeObserverProviding {
  public var appsActivationState: AnyPublisher<AppsActivationState, Never> {
    shared {
      xcodeObserver.statePublisher
        .compactMap {
          $0.activeInstance != nil
        }
        .combineLatest(isHostAppActive)
        .map { isXcodeActive, isHostAppActive in
          if isXcodeActive, isHostAppActive {
            .bothActive
          } else if isXcodeActive {
            .xcodeActive
          } else if isHostAppActive {
            .hostAppActive
          } else {
            .inactive
          }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
  }
}
