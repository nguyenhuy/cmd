// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftSyntaxMacrosTestSupport
import ThreadSafeMacro
import XCTest

/// Test for the `@ThreadSafeInitializer` macro
final class ThreadSafeInitializerMacroTests: XCTestCase {

  func testSimpleInitializer() {
    assertMacroExpansion(
      """
      @ThreadSafeInitializer([
          "count": TypeInfo<Int>(),
      ])
      init(count: Int) {
        self.count = count
      }
      """,
      expandedSource: """
        init(count: Int) {
            var _count: Int
            _count = count
            self._internalState = Atomic<_InternalState>(_InternalState(count: _count))
        }
        """,
      macros: [
        "ThreadSafeInitializer": ThreadSafeInitializerMacro.self,
      ])
  }

  func testInitializerWithOtherProperties() {
    assertMacroExpansion(
      """
      @ThreadSafeInitializer([
          "count": TypeInfo<Int>(),
      ])
      init(count: Int, bar: String) {
        foo = 1
        self.count = count
        self.bar = bar
      }
      """,
      expandedSource: """
        init(count: Int, bar: String) {
            var _count: Int
            foo = 1
            _count = count
            self._internalState = Atomic<_InternalState>(_InternalState(count: _count))
            self.bar = bar
        }
        """,
      macros: [
        "ThreadSafeInitializer": ThreadSafeInitializerMacro.self,
      ])
  }

  func testInitializerWithAllTypesOfProperties() {
    assertMacroExpansion(
      """
      @ThreadSafeInitializer([
          "count": TypeInfo<Int>(),
          "value": TypeInfo<T?>(),
          "name": TypeInfo<String?>(default: nil),
      ])
      init<T: Sendable>(count: Int, bar: String, value: T? = nil) {
        foo = 1
        self.value = value
        self.bar = bar
        self.count = count
        self.name = name
      }
      """,
      expandedSource: """
        init<T: Sendable>(count: Int, bar: String, value: T? = nil) {
            var _count: Int
            var _value: T? = nil
            let _name: String? = nil
            foo = 1
            _value = value
            self.bar = bar
            _count = count
            self._internalState = Atomic<_InternalState>(_InternalState(count: _count, value: _value, name: _name))
            self.name = name
        }
        """,
      macros: [
        "ThreadSafeInitializer": ThreadSafeInitializerMacro.self,
      ])
  }
}
