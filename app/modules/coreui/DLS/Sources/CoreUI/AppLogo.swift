// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import SwiftUI

// MARK: - AppLogo

public struct AppLogo: View {
  public var body: some View {
    SVGImage(resourceBundle.url(forResource: "cmd-logo", withExtension: "svg") ?? URL(filePath: ""))
  }

  public init() { }
}

private let resourceBundle = Bundle.module
