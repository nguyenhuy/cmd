// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies

// MARK: - FileSuggestionServiceDependencyKey

public final class FileSuggestionServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: FileSuggestionService = MockFileSuggestionService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: FileSuggestionService = () as! FileSuggestionService
  #endif
}

extension DependencyValues {
  public var fileSuggestionService: FileSuggestionService {
    get { self[FileSuggestionServiceDependencyKey.self] }
    set { self[FileSuggestionServiceDependencyKey.self] = newValue }
  }
}
