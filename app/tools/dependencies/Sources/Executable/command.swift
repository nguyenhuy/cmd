// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ArgumentParser
import Foundation
import SwiftParser
import SyncPackageDependencies

// MARK: - SyncDependencies

@main
struct SyncDependencies: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "syncDependencies",
    abstract: "Sync package dependencies between source and target paths",
    version: "1.0.0",
    subcommands: [SyncCommand.self])
}

// MARK: - SyncCommand

struct SyncCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "sync",
    abstract: "Sync package dependencies from source to target")

  @Option(name: [.short, .long], help: "The path to the package to sync")
  var path: String
  @Flag(name: [.short, .long], help: "Update all dependencies")
  var all = false

  func run() throws {
    let packagePath = URL(fileURLWithPath: path).canonicalURL
    try UpdateDependencies.update(packagePath: packagePath, all: all)
  }
}
