// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppFoundation
import Foundation

extension FileDiff {
  /// Rebase a suggested change to match the current content of a file.
  ///
  /// - Parameters:
  ///   - baselineContent: The initial content of the file before any change was made for the context of interest.
  ///   - currentContent: The current content of the file.
  ///   - targetContent: The change that was proposed from the baseline.
  /// - Returns: The rebased change, which might contain conflict markers.
  public static func rebaseChange(
    baselineContent: String,
    currentContent: String,
    targetContent: String)
    throws -> String
  {
    let uuid = UUID().uuidString
    let tmpDir = "/tmp/\(uuid)"
    try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)

    let tmpFileV0Path = "/tmp/file-0-\(uuid).txt"
    let tmpFileV1Path = "/tmp/file-1-\(uuid).txt"
    let tmpFileV2Path = "/tmp/file-2-\(uuid).txt"
    let filePath = "\(tmpDir)/file"

    FileManager.default.createFile(
      atPath: tmpFileV0Path,
      contents: baselineContent.formattedToApplyGitDiff.utf8Data,
      attributes: nil)
    FileManager.default.createFile(
      atPath: tmpFileV1Path,
      contents: currentContent.formattedToApplyGitDiff.utf8Data,
      attributes: nil)
    FileManager.default.createFile(
      atPath: tmpFileV2Path,
      contents: targetContent.formattedToApplyGitDiff.utf8Data,
      attributes: nil)

    defer {
      try? FileManager.default.removeItem(atPath: tmpFileV0Path)
      try? FileManager.default.removeItem(atPath: tmpFileV1Path)
      try? FileManager.default.removeItem(atPath: tmpFileV2Path)
      try? FileManager.default.removeItem(atPath: filePath)
      try? FileManager.default.removeItem(atPath: tmpDir)
    }

    let command = """
      cd \(tmpDir) && git init && git add . && git commit -m 'Initial commit' --allow-empty && \ 
      cp \(tmpFileV0Path) file && git add . && git commit -m 'baseline' --allow-empty && \
      git checkout -b current && git checkout -b suggestion && \
      cp \(tmpFileV2Path) file && git add . && git commit -m 'target' --allow-empty && \
      git checkout current && cp \(tmpFileV1Path) file && git add . && git commit -m 'current' --allow-empty && \
      git merge suggestion --no-edit
      """

    _ = try shell(command)
    let mergedContentData = try Data(contentsOf: URL(filePath: "\(tmpDir)/file"))
    guard let mergedContent = String(data: mergedContentData, encoding: .utf8) else {
      throw AppError(message: "Failed to read the merged content.")
    }

    return mergedContent.unformattedFromApplyGitDiff
  }
}
