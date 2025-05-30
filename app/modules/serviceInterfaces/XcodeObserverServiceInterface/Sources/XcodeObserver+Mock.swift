// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AccessibilityFoundation
@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation

public final class MockXcodeObserver: XcodeObserver {

  public init(
    _ initialValue: AXState<XcodeState>)
  {
    mutableStatePublisher = .init(initialValue)
  }

  public let mutableStatePublisher: CurrentValueSubject<AXState<XcodeState>, Never>

  public var axNotifications: AnyPublisher<AXNotification, Never> {
    Just(AXNotification.applicationActivated).eraseToAnyPublisher()
  }

  public var statePublisher: ReadonlyCurrentValueSubject<AXState<XcodeState>, Never> {
    mutableStatePublisher.readonly()
  }

}
