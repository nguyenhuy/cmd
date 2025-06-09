// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

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
