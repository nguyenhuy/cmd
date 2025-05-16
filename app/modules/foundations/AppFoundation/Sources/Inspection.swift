// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

#if DEBUG
// Used for testing purposes to inspect SwiftUI views.
// https://github.com/nalexn/ViewInspector/blob/0.10.2/guide.md#approach-2

import Combine
import SwiftUI

public final class Inspection<V> {

  public init() { }

  public let notice = PassthroughSubject<UInt, Never>()
  public var callbacks = [UInt: (V) -> Void]()

  public func visit(_ view: V, _ line: UInt) {
    if let callback = callbacks.removeValue(forKey: line) {
      callback(view)
    }
  }
}
#endif
