// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Dependencies
import DependencyFoundation
import Foundation

// MARK: - FileManagerProviding

public protocol FileManagerProviding {
  var fileManager: FileManagerI { get }
}

extension BaseProviding {
  public var fileManager: FileManagerI {
    FileManager.default
  }
}

// MARK: - FileManagerDependencyKey

public final class FileManagerDependencyKey: TestDependencyKey {
  #if DEBUG
  public static let testValue: FileManagerI = MockFileManager()
  #else
  /// This is not read outside of DEBUG
  public static let testValue: FileManagerI = () as! FileManagerI
  #endif
}

extension DependencyValues {
  public var fileManager: FileManagerI {
    get { self[FileManagerDependencyKey.self] }
    set { self[FileManagerDependencyKey.self] = newValue }
  }
}
