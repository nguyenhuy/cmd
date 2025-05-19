// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Foundation
import Testing
@testable import ServerServiceInterface

// MARK: - ErrorParsingTests

@Suite("Server Error Parsing Tests")
struct ErrorParsingTests {

  @Test("Test successful decoding")
  func testSuccessfulDecoding() async throws {
    // Setup
    let server = MockServer()
    let responseData = try #require("{ \"name\": \"Test User\", \"age\": 30 }".utf8Data)

    server.onPostRequest = { _, _, _ in
      responseData
    }

    // Execute
    let user: User = try await server.postRequest(path: "/users", data: Data())

    // Assert
    #expect(user.name == "Test User")
    #expect(user.age == 30)
  }

  @Test("Test error parsing with complete error object")
  func testErrorParsingComplete() async throws {
    // Setup
    let server = MockServer()
    let errorResponse = try #require("""
      {
          "type": "error",
          "success": false,
          "statusCode": 404,
          "message": "User not found",
          "stack": "Error stack trace information"
      }
      """.utf8Data)

    server.onPostRequest = { _, _, _ in
      errorResponse
    }

    // Execute and verify error is thrown
    do {
      let _: User = try await server.postRequest(path: "/users", data: Data())
      Issue.record("Expected an error to be thrown")
    } catch let error as APIError {
      // Assert
      #expect(error.statusCode == 404)
      #expect(error.localizedDescription == "User not found")
      #expect(error.debugDescription == "Error stack trace information")
    }
  }

  @Test("Test error parsing without stack trace")
  func testErrorParsingWithoutStack() async throws {
    // Setup
    let server = MockServer()
    let errorResponse = try #require("""
      {
          "type": "error",
          "success": false,
          "statusCode": 403,
          "message": "Forbidden"
      }
      """.utf8Data)

    server.onPostRequest = { _, _, _ in
      errorResponse
    }

    // Execute and verify error is thrown
    do {
      let _: User = try await server.postRequest(path: "/users", data: Data())
      Issue.record("Expected an error to be thrown")
    } catch let error as APIError {
      // Assert
      #expect(error.statusCode == 403)
      #expect(error.localizedDescription == "Forbidden")
      #expect(error.debugDescription == nil)
    }
  }

  @Test("Test invalid error type")
  func testInvalidErrorType() async throws {
    // Setup
    let server = MockServer()
    let errorResponse = try #require("""
      {
          "type": "not_an_error",
          "success": false,
          "statusCode": 500,
          "message": "Server error",
          "stack": "Error details"
      }
      """.utf8Data)

    server.onPostRequest = { _, _, _ in
      errorResponse
    }

    // Execute
    // Since this is not recognized as a valid error, it should attempt regular decoding
    // and fail with a decoding error
    do {
      let _: User = try await server.postRequest(path: "/users", data: Data())
      Issue.record("Expected a decoding error to be thrown")
    } catch {
      // We expect an error, this is fine.
    }
  }

  @Test("Test regular decoding error")
  func testRegularDecodingError() async throws {
    // Setup
    let server = MockServer()
    let responseData = try #require("{ \"invalid\": \"json\" }".utf8Data)

    server.onPostRequest = { _, _, _ in
      responseData
    }

    // Execute
    do {
      let _: User = try await server.postRequest(path: "/users", data: Data())
      Issue.record("Expected a decoding error to be thrown")
    } catch {
      // We expect an error, this is fine.
    }
  }

  @Test("Test no data response")
  func testNoDataResponse() async throws {
    // Setup
    let server = MockServer()
    let emptyData = Data()

    server.onPostRequest = { _, _, _ in
      emptyData
    }

    // Execute
    do {
      let _: User = try await server.postRequest(path: "/users", data: Data())
      Issue.record("Expected an error to be thrown")
    } catch {
      // We expect an error, this is fine.
    }
  }
}

// MARK: - User

/// Helper struct for testing purposes
struct User: Decodable {
  let name: String
  let age: Int
}
