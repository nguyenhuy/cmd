// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation

#if DEBUG
// MARK: - MockAppHandlerRegistry

public final class MockAppEventHandlerRegistry: AppEventHandlerRegistry {

  public init() {
    onRegisterHandler = { [weak self] handler in
      self?.state.mutate { $0.eventHandlers.append(handler) }
    }
    onHandle = { [weak self] event in
      guard let self else { return false }

      for handler in state.value.eventHandlers {
        if await handler(event) {
          return true
        }
      }
      return false
    }
  }

  public var onRegisterHandler: @Sendable (_ handler: @Sendable @escaping (_ appEvent: AppEvent) async -> Bool)
    -> Void
  {
    set { state.mutate { $0.onRegisterHandler = newValue } }
    get { state.value.onRegisterHandler }
  }

  public var onHandle: @Sendable (_ event: AppEvent) async -> Bool {
    set { state.mutate { $0.onHandle = newValue } }
    get { state.value.onHandle }
  }

  public func registerHandler(_ handler: @Sendable@escaping (_ appEvent: AppEvent) async -> Bool) {
    state.value.onRegisterHandler(handler)
  }

  public func handle(event: AppEvent) async -> Bool {
    await state.value.onHandle(event)
  }

  private struct State: Sendable {
    var eventHandlers: [@Sendable (_ appEvent: AppEvent) async -> Bool] = []
    var onRegisterHandler: @Sendable (_ handler: @Sendable @escaping (_ appEvent: AppEvent) async -> Bool)
      -> Void = { _ in }
    var onHandle: @Sendable (_ event: AppEvent) async -> Bool = { _ in true }
  }

  private let state = Atomic(State())
}
#endif
