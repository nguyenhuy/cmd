// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  public subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
