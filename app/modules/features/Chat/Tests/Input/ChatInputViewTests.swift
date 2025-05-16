// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import ConcurrencyFoundation
import DLS
import SwiftUI
import Testing
import ViewInspector
import XCTest
@testable import Chat

// MARK: - Inspection + InspectionEmissary, @unchecked Sendable

extension Inspection: InspectionEmissary, @unchecked Sendable { }

// MARK: - ChatInputViewTests

class ChatInputViewTests: XCTestCase {
  @MainActor
  func test_writeInput_updatesViewModel() async throws {
    let viewModel = ChatInputViewModel()
    let isStreamingResponse = Atomic<Bool>(false)

    let sut = ChatInputView(
      inputViewModel: viewModel,
      isStreamingResponse: isStreamingResponse.binding,
      didTapCancel: { },
      didSend: { })
    try await ViewHosting.host(sut) {
      try await sut.inspection.inspect { view in
        let textView = try view.find(RichTextEditor.self).actualView().nsView()
        textView.insertText("Hi can you help me?", replacementRange: NSRange(location: 0, length: 0))
      }
    }
    ViewHosting.expel()
    XCTAssertEqual(viewModel.textInput.string.string, "Hi can you help me?")
  }

//  @MainActor
//  func test_sendButton_sendsInput() async throws {
//    let viewModel = ChatInputViewModel()
//    let isStreamingResponse = Atomic<Bool>(false)
//    let exp = expectation(description: "message sent")
//
//    let sut = ChatInputView(
//      inputViewModel: viewModel,
//      isStreamingResponse: isStreamingResponse.binding,
//      didTapCancel: { },
//      didSend: { exp.fulfill() })
//    try await ViewHosting.host(sut) {
//      try await sut.inspection.inspect { view in
//        let textView = try view.find(RichTextEditor.self).actualView().nsView()
//        textView.insertText("Hi can you help me?", replacementRange: NSRange(location: 0, length: 0))
//        try view.find(viewWithId: "chat button").findAll(ViewType.Button.self).first?.tap()
//      }
//    }
//    ViewHosting.expel()
//    await fulfillment(of: [exp])
//  }

}

extension Atomic {
  var binding: Binding<Value> {
    Binding(
      get: { self.value },
      set: { self.set(to: $0) })
  }
}
