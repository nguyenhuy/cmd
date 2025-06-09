// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

public struct ModelPricing: Sendable, Codable {
  init(input: Double, output: Double, cacheWrite: Double, cachedInput: Double, inputImage: Double? = nil) {
    self.input = input
    self.output = output
    self.cacheWrite = cacheWrite
    self.cachedInput = cachedInput
    self.inputImage = inputImage
  }

  init(input: Double, output: Double, cacheWriteMult: Double, cachedInputMult: Double, inputImage: Double? = nil) {
    self.input = input
    self.output = output
    cacheWrite = input * (1 + cacheWriteMult)
    cachedInput = input * cachedInputMult
    self.inputImage = inputImage
  }

  public let input: Double
  public let output: Double
  public let cacheWrite: Double
  public let cachedInput: Double
  public let inputImage: Double?

}
