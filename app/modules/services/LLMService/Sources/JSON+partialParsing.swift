// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

//
//  JSON+partialParsing.swift
//  Packages
//
//  Created by Guigui on 5/15/25.
//
import Foundation
import JSONScanner

extension String {
  /// Extracts a partial JSON object from the string.
  func extractPartialJSON() throws -> (data: Data, isValidJSON: Bool) {
    try Data(utf8).extractPartialJSON()
  }
}

extension Data {
  /// Extracts a partial JSON object that has not been completely received.
  ///
  /// - Keys that are not complete are dropped
  /// - Values, other than string and arrays that are not complete received are dropped, along with their keys.
  /// - The returned data is a valid JSON. Closing characters (", ], }) might be added.
  func extractPartialJSON() throws -> (data: Data, isValidJSON: Bool) {
    if count == 0 {
      return (Data("{}".utf8), false)
    }
    var openDelimiters = [UInt8]()
    let lastValidIndex = withUnsafeBytes { bytes in
      var scanner = JSONScanner(source: bytes, options: .init())
      var lastValidIndex = bytes.startIndex
      do {
        try scanner.skipPartialValue(openDelimiters: &openDelimiters, lastValidIndex: &lastValidIndex) //
        return bytes.endIndex
      } catch {
        if openDelimiters.last == asciiDoubleQuote {
          // Keep partial string value content
          return lastValidIndex
        }
        if lastValidIndex > 0, bytes[lastValidIndex - 1] == asciiComma {
          // the last valid index is a comma, remove it before closing the JSON
          lastValidIndex -= 1
        }
        return lastValidIndex
      }
    }
    if lastValidIndex == endIndex, openDelimiters.isEmpty {
      return (data: self, isValidJSON: true)
    }
    var truncatedData = prefix(lastValidIndex)
    for delimiter in openDelimiters.reversed() {
      truncatedData.append(delimiter)
    }

    return (data: truncatedData, isValidJSON: false)
  }
}

extension JSONScanner {

  /// Similar to skipString, but working with truncated data.
  /// This will push to `openDelimiters` the delimiters that have been opened and not closed.
  /// `lastValidIndex` will be updated to the last position where data could be parsed.
  ///
  /// Advance the index past the next complete quoted string.
  public mutating func skipPartialString(lastValidIndex: inout UnsafeRawBufferPointer.Index) throws {
    guard hasMoreContent else {
      throw JSONDecodingError.truncated
    }
    if currentByte != asciiDoubleQuote {
      throw JSONDecodingError.malformedString
    }
    advance()
    while hasMoreContent {
      let c = currentByte
      switch c {
      case asciiDoubleQuote:
        advance()
        return

      case asciiBackslash:
        advance()
        guard hasMoreContent else {
          throw JSONDecodingError.truncated
        }
        advance()

      default:
        advance()
      }
      lastValidIndex = index
    }
    throw JSONDecodingError.truncated
  }

  /// Similar to skipValue, but working with truncated data.
  /// This will push to `openDelimiters` the delimiters that have been opened and not closed.
  /// `lastValidIndex` will be updated to the last position where data could be parsed.
  ///
  /// Advance index past the next value.  This is used
  /// by skip() and by unknown field handling.
  /// Note: This handles objects {...} recursively but arrays [...] non-recursively
  /// This avoids us requiring excessive stack space for deeply nested
  /// arrays (which are not included in the recursion budget check).
  mutating func skipPartialValue(openDelimiters: inout [UInt8], lastValidIndex: inout UnsafeRawBufferPointer.Index) throws {
    skipWhitespace()
    var totalArrayDepth = 0
    while true {
      var arrayDepth = 0
      while skipOptionalArrayStart() {
        openDelimiters.append(asciiCloseSquareBracket)
        lastValidIndex = index
        arrayDepth += 1
      }
      guard hasMoreContent else {
        throw JSONDecodingError.truncated
      }
      switch currentByte {
      case asciiDoubleQuote: // " begins a string
        openDelimiters.append(asciiDoubleQuote)
        try skipPartialString(lastValidIndex: &lastValidIndex)
        openDelimiters.removeLast()
        lastValidIndex = index

      case asciiOpenCurlyBracket: // { begins an object
        try skipPartialObject(openDelimiters: &openDelimiters, lastValidIndex: &lastValidIndex)

      case asciiCloseSquareBracket: // ] ends an empty array
        if arrayDepth == 0 {
          throw JSONDecodingError.failure
        }
        // We also close out [[]] or [[[]]] here
        while arrayDepth > 0, skipOptionalArrayEnd() {
          arrayDepth -= 1
          openDelimiters.removeLast()
        }
        lastValidIndex = index

      case asciiLowerN: // n must be null
        if
          !skipOptionalKeyword(bytes: [
            asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL,
          ])
        {
          throw JSONDecodingError.truncated
        }
        lastValidIndex = index

      case asciiLowerF: // f must be false
        if
          !skipOptionalKeyword(bytes: [
            asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE,
          ])
        {
          throw JSONDecodingError.truncated
        }
        lastValidIndex = index

      case asciiLowerT: // t must be true
        if
          !skipOptionalKeyword(bytes: [
            asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE,
          ])
        {
          throw JSONDecodingError.truncated
        }
        lastValidIndex = index

      default: // everything else is a number token
        _ = try nextDouble()
        // Don't move lastValidIndex here, as we are not sure if we have read all the number.
        // For instance if the true value is 123 and we can only read 12,
        // we don't output any value instead of outputting a nonsensical value.
      }
      totalArrayDepth += arrayDepth
      while totalArrayDepth > 0, skipOptionalArrayEnd() {
        totalArrayDepth -= 1
        openDelimiters.removeLast()
        lastValidIndex = index
      }
      if totalArrayDepth > 0 {
        try skipRequiredComma()
        lastValidIndex = index
      } else {
        return
          lastValidIndex = index
      }
    }
  }

  /// Similar to skipObject, but working with truncated data.
  /// This will push to `openDelimiters` the delimiters that have been opened and not closed.
  /// `lastValidIndex` will be updated to the last position where data could be parsed.
  ///
  /// Advance the index past the next complete {...} construct.
  mutating func skipPartialObject(openDelimiters: inout [UInt8], lastValidIndex: inout UnsafeRawBufferPointer.Index) throws {
    try skipRequiredObjectStart()
    lastValidIndex = index
    openDelimiters.append(asciiCloseCurlyBracket)
    if skipOptionalObjectEnd() {
      return
    }
    while true {
      skipWhitespace()
      try skipString()
      try skipRequiredColon()
      try skipPartialValue(openDelimiters: &openDelimiters, lastValidIndex: &lastValidIndex)
      if skipOptionalObjectEnd() {
        openDelimiters.removeLast()
        lastValidIndex = index
        return
      }
      try skipRequiredComma()
    }
  }

}
