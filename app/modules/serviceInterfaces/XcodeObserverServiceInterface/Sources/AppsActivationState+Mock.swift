// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Combine

extension AppsActivationState {
  public static func mockPublisher() -> AnyPublisher<AppsActivationState, Never> {
    Just(.inactive).eraseToAnyPublisher()
  }
}
