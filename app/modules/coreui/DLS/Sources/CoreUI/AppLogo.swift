// Copyright cmd app, Inc. Licensed under the Apache License, Version 2.0.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

import SwiftUI

// MARK: - AppLogo

public struct AppLogo: View {
  public var body: some View {
    SVGImage(resourceBundle.url(forResource: "cmd-logo", withExtension: "svg") ?? URL(filePath: ""))
  }

  public init() { }
}

private let resourceBundle = Bundle.module
