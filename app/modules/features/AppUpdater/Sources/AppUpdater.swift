// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

//// Copyright command. All rights reserved.
//// Licensed under the XXX License. See License.txt in the project root for license information.
//
// import Sparkle
// import SwiftUI
//
//// MARK: - CheckForUpdatesViewModel
//
///// This view model class publishes when new updates can be checked by the user
// final class CheckForUpdatesViewModel: ObservableObject {
//  init(updater: SPUUpdater) {
//    updater.publisher(for: \.canCheckForUpdates)
//      .assign(to: &$canCheckForUpdates)
//  }
//
//  @Published var canCheckForUpdates = false
//
// }
//
//// MARK: - CheckForUpdatesView
//
///// This is the view for the Check for Updates menu item
///// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
///// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
// struct CheckForUpdatesView: View {
//  @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
//  private let updater: SPUUpdater
//
//  init(updater: SPUUpdater) {
//    self.updater = updater
//
//    // Create our view model for our CheckForUpdatesView
//    checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
//  }
//
//  var body: some View {
//    Button("Check for Updates…", action: updater.checkForUpdates)
//      .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
//  }
// }
//
// extension SPUStandardUpdaterController {
//  static let shared = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
// }
//
// extension SPUStandardUpdaterController: @retroactive @unchecked Sendable { }
