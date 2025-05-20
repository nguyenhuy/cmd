// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - ViewSizeReader

/// A view that reads the size of its content and reports it via a binding.
public struct ViewSizeReader<Content: View>: View {

  public init(
    content: Content,
    size: Binding<CGSize>)
  {
    self.content = content
    _size = size
  }

  public var body: some View {
    Rectangle()
      .frame(width: 0, height: 0)
      .overlay {
        content
          .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
          } action: { newValue in
            size = newValue
          }
          .hidden()
      }
  }

  @Binding private var size: CGSize

  private let content: Content
}

extension View {
  /// Reads the size of this view and reports it via a binding.
  public func readSize(_ size: Binding<CGSize>) -> some View {
    ViewSizeReader(content: self, size: size)
  }

  /// Reads the size of this view and reports it via a callback.
  public func readSize(_ read: @escaping @MainActor (CGSize) -> Void) -> some View {
    ViewSizeReader(content: self, size: Binding(
      get: { .zero },
      set: { newValue in read(newValue) }))
  }

  /// Reads the size of this view and reports it via a binding. Also display the view.
  public func readingSize(_ read: @escaping @MainActor (CGSize) -> Void) -> some View {
    onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { size in
      read(size)
    }
  }
}

#Preview {
  struct PreviewView: View {
    @State private var size = CGSize.zero

    var body: some View {
      VStack {
        Text("Hello, World!")
          .readSize($size)
        Text("Size: \(Int(size.width))x\(Int(size.height))")
      }
      .padding()
    }
  }

  return PreviewView()
}

// Starting form Xcode 16.3 / Swift 6.1 not having this was causing a compiler crash when building a release build from xcodebuild.
// TODO: Remove if the release build passes without.
extension CGSize: @retroactive @unchecked Sendable {}
