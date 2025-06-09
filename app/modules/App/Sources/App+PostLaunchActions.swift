// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

//
//  App+PostLaunchActions.swift
//  Packages
//
//  Created by Guigui on 6/4/25.
//
import AppUpdateServiceInterface
import Dependencies
import XcodeObserverServiceInterface

extension commandApp {
  func postLaunchActions() {
    Task {
      // Initialize the local server on launch
      @Dependency(\.server) var server
      _ = try? await server.getRequest(path: "launch")
    }
    // Initiate the service to start automatic updates
    @Dependency(\.appUpdateService) var appUpdateService
    _ = appUpdateService
  }
}
