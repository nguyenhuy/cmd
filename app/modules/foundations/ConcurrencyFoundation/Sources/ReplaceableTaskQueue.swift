// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine

/// A queue that manages asynchronous tasks where new tasks replace any pending task.
///
/// `ReplaceableTaskQueue` executes tasks sequentially with the following behavior:
/// - If no task is running, the queued task starts immediately
/// - If a task is running, any previously pending task is replaced by the newly queued task
/// - Currently executing tasks run to completion and are not interrupted
///
/// Example usage:
/// ```swift
/// let queue = ReplaceableTaskQueue<String>()
/// queue.sink { result in
///     print("Completed task with result: \(result)")
/// }
///
/// // If these are queued while no task is running, task1 starts immediately
/// queue.queue { await task1() } // This will complete
/// queue.queue { await task2() } // This replaces any pending task
/// queue.queue { await task3() } // This replaces task2, will run after task1 finishes
/// ```
///
/// The queue implements the `Publisher` protocol, allowing you to subscribe to task results
/// using Combine's subscription methods.
public final class ReplaceableTaskQueue<Output>: Sendable, Publisher {

  public init() { }

  public typealias Failure = Never

  public func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Never {
    publisher.compactMap(\.self).subscribe(subscriber)
  }

  public func queue(_ task: @escaping @Sendable () async throws -> Output) {
    state.mutate { $0.nextTask = task }
    dequeue()
  }

  private struct State: Sendable {
    var currentTask: (@Sendable () async throws -> Output)?
    var nextTask: (@Sendable () async throws -> Output)?
  }

  private let publisher = CurrentValueSubject<Output?, Failure>(nil)

  private let state = Atomic<State>(State())

  private func dequeue() {
    let task: (@Sendable () async throws -> Output)? = state.mutate { state in
      if state.currentTask == nil, let nextTask = state.nextTask {
        state.nextTask = nil
        state.currentTask = nextTask
        return nextTask
      }
      return nil
    }

    if let task {
      Task { [weak self] in
        do {
          let output = try await task()
          guard let self else { return }
          state.mutate { $0.currentTask = nil }
          publisher.send(output)
        } catch {
          // for now, do nothing with the error.
        }
        self?.dequeue()
      }
    }
  }

}
