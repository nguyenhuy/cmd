// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import Foundation
import SwiftUI

// MARK: - Attachment

enum Attachment: Identifiable {
  case file(FileAttachment)
  case image(ImageAttachment)
  case fileSelection(FileSelectionAttachment)
  case buildError(BuildError)

  struct FileAttachment: Identifiable {
    let id = UUID()
    let path: URL
    let content: String
  }

  struct ImageAttachment: Identifiable {

    @MainActor
    init(imageData: Data, path: URL?) {
      self.imageData = imageData
      self.path = path

      let image = ObservableValue<Image?>(nil)
      self.image = image

      // Load the image async
      Task.detached {
        if #available(macOS 15.2, *) {
          let img = try await Image(importing: imageData, contentType: nil)
          Task { @MainActor in
            image.value = img
          }
        } else {
          let nsImage = NSImage(data: imageData) ?? NSImage(systemSymbolName: "photo", accessibilityDescription: nil) ?? NSImage()
          let img = Image(nsImage: nsImage)

          Task { @MainActor in
            image.value = img
          }
        }
      }
    }

    let id = UUID()
    let imageData: Data
    let path: URL?

    let image: ObservableValue<Image?>
  }

  struct FileSelectionAttachment: Identifiable {
    let id = UUID()
    let file: FileAttachment
    let startLine: Int
    let endLine: Int
  }

  struct BuildError: Identifiable {
    let id = UUID()
    let message: String
    let filePath: URL
    let line: Int
    let column: Int
  }

  var file: FileAttachment? {
    switch self {
    case .file(let attachment):
      attachment
    default:
      nil
    }
  }

  var image: ImageAttachment? {
    switch self {
    case .image(let attachment):
      attachment
    default:
      nil
    }
  }

  var fileSelection: FileSelectionAttachment? {
    switch self {
    case .fileSelection(let attachment):
      attachment
    default:
      nil
    }
  }

  var id: UUID {
    switch self {
    case .file(let attachment): attachment.id
    case .image(let attachment): attachment.id
    case .fileSelection(let attachment): attachment.id
    case .buildError(let attachment): attachment.id
    }
  }
}

// MARK: Equatable

extension Attachment: Equatable {
  /// Executes a cheap comparison between the attachments based on their id.
  /// This is meant to be used in SwiftUI after it has been verified once that no two attachments with the same content have been created.
  /// - Returns: `true` if both attachments have the same id, `false` otherwise
  static func ==(lhs: Attachment, rhs: Attachment) -> Bool {
    lhs.id == rhs.id
  }

  /// Executes a deep comparison between two attachments.
  /// - Returns: `true` if both attachments describe the same underlying content, `false` otherwise
  static func ===(lhs: Attachment, rhs: Attachment) -> Bool {
    switch (lhs, rhs) {
    case (.file(let lhs), .file(let rhs)):
      lhs.path == rhs.path
    case (.image, .image):
      false // TODO: is this needed?
    case (.fileSelection(let lhs), .fileSelection(let rhs)):
      lhs.file.path == rhs.file.path && lhs.startLine == rhs.startLine && lhs.endLine == rhs.endLine
    case (.buildError(let lhs), .buildError(let rhs)):
      lhs.filePath == rhs.filePath && lhs.line == rhs.line && lhs.column == rhs.column && lhs.message == rhs.message
    default:
      false
    }
  }
}
