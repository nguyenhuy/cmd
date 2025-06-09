// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies

// MARK: - CheckpointServiceDependencyKey

public final class CheckpointServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: CheckpointService = MockCheckpointService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: CheckpointService = () as! CheckpointService
  #endif
}

extension DependencyValues {
  public var checkpointService: CheckpointService {
    get { self[CheckpointServiceDependencyKey.self] }
    set { self[CheckpointServiceDependencyKey.self] = newValue }
  }
}
