// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppExtension
import Foundation
import FoundationInterfaces
import LoggingServiceInterface
import SharedValuesFoundation

// MARK: - LocalServer

final class LocalServer {

  func send<Response: Decodable>(command: String, input: some Codable) async throws -> Response {
    try await send(command: command, input: input, retryCount: 0)
  }

  private func send<Response: Decodable>(command: String, input: some Codable, retryCount: Int) async throws -> Response {
    #if DEBUG
    let userDefaults = try UserDefaults.shared(bundle: Bundle.main)
    #else
    let userDefaults = AppExtensionScope.shared.sharedUserDefaults.bool(forKey: SharedKeys.pointReleaseXcodeExtensionToDebugApp)
      ? try UserDefaults.debugShared(bundle: Bundle.main)
      : try UserDefaults.shared(bundle: Bundle.main)
    #endif
    guard let port = userDefaults?.integer(forKey: UserDefaultKeys.localServerPort) else {
      defaultLogger.error("Could not find a port to connect to the local server.")
      throw XcodeExtensionError(message: "Failed to run.")
    }

    // Send command to host app.
    guard let url = URL(string: "http://localhost:\(port)/execute-command") else {
      defaultLogger.error("Could not create a URL for the local server at port \(port)")
      throw XcodeExtensionError(message: "Failed to run.")
    }
    defaultLogger.log("Sending command \(command) to local server.")

    do {
      let bodyData = try JSONEncoder().encode(ExtensionRequest(command: command, input: input))
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = bodyData
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let (data, _) = try await URLSession.shared.data(for: request)
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
      if
        (error as? URLError)?.code == .cannotConnectToHost,
        retryCount == 0,
        !AppExtensionScope.shared.sharedUserDefaults.bool(forKey: SharedKeys.pointReleaseXcodeExtensionToDebugApp)
      {
        // If we could not connect to the host app, try to open it and retry once.
        try OpenHostApp.openHostApp()
        return try await send(command: command, input: input, retryCount: retryCount + 1)
      }
      defaultLogger.error("Failed to send command to the local server: \(error)")
      throw XcodeExtensionError(message: "Failed to run.")
    }
  }

}
