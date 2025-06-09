// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import ChatFeatureInterface
import DLS
import SwiftUI

// MARK: - ImageAttachmentPickerView

struct ImageAttachmentPickerView: View {

  var attachments: Binding<[AttachmentModel]>

  var body: some View {
    IconButton(
      action: {
        selectImage()
      },
      systemName: "photo",
      cornerRadius: 0)
      .foregroundColor(.primary)
  }

  private func selectImage() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.image]

    panel.begin { response in
      if response == .OK {
        handleSelectedImages(panel.urls)
      }
    }
  }

  private func handleSelectedImages(_ urls: [URL]) {
    // Process selected images
    let newAttachments = urls.compactMap { url -> AttachmentModel? in
      guard let data = try? Data(contentsOf: url) else {
        // TODO: show the error
        return nil
      }

      return AttachmentModel.image(.init(imageData: data, path: url))
    }
    var allAttachments = attachments.wrappedValue
    allAttachments.append(contentsOf: newAttachments)
    attachments.wrappedValue = allAttachments
  }
}

#if DEBUG
#Preview {
  ImageAttachmentPickerView(attachments: .constant([]))
}
#endif
