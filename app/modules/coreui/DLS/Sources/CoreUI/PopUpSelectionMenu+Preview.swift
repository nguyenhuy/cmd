// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import SwiftUI

#if DEBUG
struct TestItem: MenuItem, CaseIterable {
  static var allCases: [TestItem] { [.itemA, .itemB] }

  let id: String = UUID().uuidString
  let displayText: String

  static let itemA = TestItem(displayText: "photo.artframe")
  static let itemB = TestItem(displayText: "surfboard")
}

@MainActor private let previews: some View = VStack {
  VStack(alignment: .leading) {
    Spacer()
    HStack(alignment: .top) {
      PopUpSelectionMenu(
        selectedItem: .constant(TestItem.itemA),
        availableItems: TestItem.allCases)
      {
        Text($0.displayText)
      }
      Divider()
        .frame(height: 10)
      Text("some other text")
      Spacer()
    }
  }
  .frame(width: 300)
  .padding()
  .background(.background)

  PopUpSelectionMenu(
    selectedItem: .constant(TestItem.itemB),
    availableItems: TestItem.allCases)
  {
    Icon(systemName: $0.displayText)
  }
  .frame(width: 300)
  .padding()
  .background(.background)
}

#Preview("Light mode") {
  previews.environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
  previews.environment(\.colorScheme, .dark)
}
#endif
