// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import ConcurrencyFoundation
import DLS
import SwiftUI

// MARK: - AttachmentItemView

struct AttachmentItemView: View {

  init(
    attachment: Attachment,
    removeAttachment: ((Attachment) -> Void)? = nil,
    primaryAction: ((Attachment) -> Void)? = nil)
  {
    self.attachment = attachment
    self.removeAttachment = removeAttachment
    self.primaryAction = primaryAction

    if case .image(let imageAttachment) = attachment {
      image = imageAttachment.image
    } else {
      image = .constant(nil)
    }
  }

  let attachment: Attachment

  var body: some View {
    RoundedButton(
      padding: EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5),
      action: { })
    {
      HStack(spacing: 4) {
        if showRemoveButton {
          removeButton
        }
        Button(action: {
          primaryAction?(attachment)
        }) {
          details
            .background(Color.tappableClearButton)
        }.buttonStyle(.plain)
      }
    }
  }

  private let primaryAction: ((Attachment) -> Void)?
  private let removeAttachment: ((Attachment) -> Void)?

  @Bindable private var image: ObservableValue<Image?>

  @ViewBuilder
  private var details: some View {
    switch attachment {
    case .image:
      HStack {
        (image.value ?? Image(systemName: "photo"))
          .resizable()
          .scaledToFit()
          .frame(width: 15, height: 15)
        Text("Image")
      }

    case .file(let file):
      HStack(spacing: 3) {
        FileIcon(filePath: file.path)
          .frame(width: 12, height: 12)
        Text(file.path.lastPathComponent)
      }

    case .fileSelection(let fileSelection):
      HStack(spacing: 3) {
        FileIcon(filePath: fileSelection.file.path)
          .frame(width: 12, height: 12)
        Text("\(fileSelection.file.path.lastPathComponent) (\(fileSelection.startLine)-\(fileSelection.endLine))")
      }

    case .buildError:
      HStack { }
    }
  }

  private var removeButton: some View {
    Button(action: {
      removeAttachment?(attachment)
    }) {
      Image(systemName: "xmark")
        .font(.system(size: 10, weight: .semibold))
        .tappableTransparentBackground()
    }.buttonStyle(.plain)
  }

  private var showRemoveButton: Bool {
    removeAttachment != nil
  }
}
