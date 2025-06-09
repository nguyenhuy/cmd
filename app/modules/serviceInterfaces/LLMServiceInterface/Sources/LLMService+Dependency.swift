// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import Dependencies

// MARK: - LLMServiceDependencyKey

public final class LLMServiceDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: LLMService = MockLLMService()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: LLMService = () as! LLMService
  #endif
}

extension DependencyValues {
  public var llmService: LLMService {
    get { self[LLMServiceDependencyKey.self] }
    set { self[LLMServiceDependencyKey.self] = newValue }
  }
}

// MARK: - LLMServiceProviding

public protocol LLMServiceProviding {
  var llmService: LLMService { get }
}
