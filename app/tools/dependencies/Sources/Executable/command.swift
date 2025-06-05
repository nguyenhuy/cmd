// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ArgumentParser
import Foundation
import SwiftParser
import SyncPackageDependencies

// MARK: - SyncDependencies

@main
struct SyncDependencies: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "syncDependencies",
    abstract: "Sync package dependencies between source and target paths",
    version: "1.0.0",
    subcommands: [SyncCommand.self, FocusCommand.self])
}

// MARK: - SyncCommand

struct SyncCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "sync",
    abstract: "Sync package dependencies from source to target")

  @Option(name: [.short, .long], help: "The path to the root package file to sync")
  var path: String
  @Flag(name: [.short, .long], help: "Also update local package files for each module")
  var all = false

  func run() throws {
    let packagePath = URL(fileURLWithPath: path).canonicalURL
    _ = try UpdateDependencies.update(packagePath: packagePath, all: all)
  }
}

// MARK: - FocusCommand

struct FocusCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "focus",
    abstract: "Create a Package.swift focussed on the specified packages and their dependencies")

  @Option(name: [.short, .long], help: "The path to the root package file")
  var path: String
  @Option(name: [.short, .long], help: "The module to focus on")
  var module = ""
  @Flag(name: [.short, .long], help: "List available dependencies")
  var list = false

  func run() throws {
    let packagePath = URL(fileURLWithPath: path).canonicalURL

    if list {
      let modulesInfo = try UpdateDependencies.update(packagePath: packagePath, all: false)
      print("\(modulesInfo.keys.joined(separator: "\n"))\n")
      return
    }
    guard
      let module = try UpdateDependencies.update(packagePath: packagePath, all: true)[module],
      let modulePath = module.modulePath
    else {
      FocusCommand.exit(withError: NSError(
        domain: "SyncDependenciesError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not find module \(module)"]))
    }

    print(modulePath.canonicalURL.appending(path: "Package.swift").path + "\n")
  }
}
