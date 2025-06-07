// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import Foundation
import Testing

@testable import ChatFeature

// MARK: - TextFormatterTests

@MainActor
struct TextFormatterTests {
  @MainActor
  struct CodeHeaderTest {

    @Test("without language")
    func test_withoutLanguage() throws {
      let formatter = TextFormatter()

      formatter.ingest(delta: """
        ```
        func add(a: Int, b: Int) -> Int
        ```
        """)

      #expect(formatter.elements.count == 1)
      #expect(formatter.elements[0].asCodeBlock?.content == """
        func add(a: Int, b: Int) -> Int
        """)
      #expect(formatter.elements[0].asCodeBlock?.language == nil)
      #expect(formatter.elements[0].asCodeBlock?.filePath == nil)
    }

    @Test("With language")
    func test_withLanguage() throws {
      let formatter = TextFormatter()

      formatter.ingest(delta: """
        ```swift
        func add(a: Int, b: Int) -> Int
        ```
        """)

      #expect(formatter.elements.count == 1)
      #expect(formatter.elements[0].asCodeBlock?.content == """
        func add(a: Int, b: Int) -> Int
        """)
      #expect(formatter.elements[0].asCodeBlock?.language == "swift")
    }

    @Test("With language and file path")
    func test_withLanguageAndFilePath() throws {
      let formatter = TextFormatter()

      formatter.ingest(delta: """
        ```swift:/file/to/path.swift
        func add(a: Int, b: Int) -> Int
        ```
        """)

      #expect(formatter.elements.count == 1)
      #expect(formatter.elements[0].asCodeBlock?.content == """
        func add(a: Int, b: Int) -> Int
        """)
      #expect(formatter.elements[0].asCodeBlock?.language == "swift")
      #expect(formatter.elements[0].asCodeBlock?.filePath == "/file/to/path.swift")
    }

    @Test("With only file path")
    func test_withonlyFilePath() throws {
      let formatter = TextFormatter()

      formatter.ingest(delta: """
        ```/file/to/path.swift
        func add(a: Int, b: Int) -> Int
        ```
        """)

      #expect(formatter.elements.count == 1)
      #expect(formatter.elements[0].asCodeBlock?.content == """
        func add(a: Int, b: Int) -> Int
        """)
      #expect(formatter.elements[0].asCodeBlock?.language == nil)
      #expect(formatter.elements[0].asCodeBlock?.filePath == "/file/to/path.swift")
    }

    @Test("With language and file path across chunks")
    func test_withLanguageAndFilePathAcrossChunks() throws {
      let formatter = TextFormatter()

      formatter.ingest(delta: """
        ```swift
        """)

      formatter.ingest(delta: """
        :/file/t
        """)

      formatter.ingest(delta: """
        o/path.swift
        func add(a: Int, b: Int) -> Int
        ```
        """)

      #expect(formatter.elements.count == 1)
      #expect(formatter.elements[0].asCodeBlock?.content == """
        func add(a: Int, b: Int) -> Int
        """)
      #expect(formatter.elements[0].asCodeBlock?.language == "swift")
      #expect(formatter.elements[0].asCodeBlock?.filePath == "/file/to/path.swift")
    }
  }

  @Test("handle text chunks and trim progressively")
  func test_textChunks() throws {
    var deltas = [
      " Hi how is ",
      "your day going?",
    ]
    let formatter = TextFormatter()

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 1)
    // Note that the trailing space of the first delta is not included yet.
    #expect(formatter.elements[0].asText?.text == "Hi how is")

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 1)
    #expect(formatter.elements[0].asText?.text == "Hi how is your day going?")
  }

  @Test("handle text chunks and code block")
  func test_textChunksAndCodeBlock() throws {
    var deltas = [
      "try this\n",
      """
      ```
      let a = 1
      ```
      """,
      "thanks",
    ]
    let formatter = TextFormatter()

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 1)
    #expect(formatter.elements.last?.asText?.text == "try this")

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 2)
    let codeBlock = try #require(formatter.elements.last?.asCodeBlock)
    #expect(codeBlock.content == "let a = 1")
    #expect(codeBlock.isComplete == true)

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 3)
    #expect(formatter.elements.last?.asText?.text == "thanks")
  }

  @Test("handle code over several deltas")
  func test_codeOverSeveralDeltas() throws {
    var deltas = [
      "try this\n",
      """
      ```
      let a = 1

      """,
      """
      ```
      """,
      "thanks",
    ]
    let formatter = TextFormatter()

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 1)
    #expect(formatter.elements.last?.asText?.text == "try this")

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 2)
    var codeBlock = try #require(formatter.elements.last?.asCodeBlock)
    #expect(codeBlock.content == "let a = 1")
    #expect(codeBlock.isComplete == false)

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 2)
    codeBlock = try #require(formatter.elements.last?.asCodeBlock)
    #expect(codeBlock.content == "let a = 1")
    #expect(codeBlock.isComplete == true)

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 3)
    #expect(formatter.elements.last?.asText?.text == "thanks")
  }

  @Test("handle split code tags")
  func test_splitCodeTag() throws {
    var deltas = [
      """
      ```
      let a = 1
      `
      """,
      """
      ``
      thanks
      """,
    ]
    let formatter = TextFormatter()

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 1)
    var codeBlock = try #require(formatter.elements.last?.asCodeBlock)
    #expect(codeBlock.content == "let a = 1")
    #expect(codeBlock.isComplete == false)

    formatter.ingest(delta: deltas.popFirst())
    #expect(formatter.elements.count == 2)
    codeBlock = try #require(formatter.elements.first?.asCodeBlock)
    #expect(codeBlock.content == "let a = 1")
    #expect(codeBlock.isComplete == true)

    #expect(formatter.elements.last?.asText?.text == "thanks")
  }

  @Test("Several code blocks at once")
  func test_severalCodeBlocksAtOnce() throws {
    let formatter = TextFormatter()

    formatter.ingest(delta: """



            ```
            let a = 1
            ```

            then

            ```
            let b = 2
            ```

      """)
    #expect(formatter.elements.count == 3)
    #expect(formatter.elements[0].asCodeBlock?.content == "let a = 1")
    #expect(formatter.elements[0].asCodeBlock?.isComplete == true)
    #expect(formatter.elements[1].asText?.text == "then")
    #expect(formatter.elements[2].asCodeBlock?.content == "let b = 2")
    #expect(formatter.elements[2].asCodeBlock?.isComplete == true)
  }

  @Test("Empty code block code blocks")
  func test_emptyCodeBlock() throws {
    let formatter = TextFormatter()

    formatter.ingest(delta: """
            empty code:
            ``````
            or
            ```
            ```
            or
            ```   ```
      """)
    #expect(formatter.elements.count == 6)
    #expect(formatter.elements[0].asText?.text == "empty code:")
    #expect(formatter.elements[1].asCodeBlock?.content == "")
    #expect(formatter.elements[2].asText?.text == "or")
    #expect(formatter.elements[3].asCodeBlock?.content == "")
    #expect(formatter.elements[4].asText?.text == "or")
    #expect(formatter.elements[5].asCodeBlock?.content == "")
  }

  @Test("Escaping")
  func test_escaping() throws {
    let formatter = TextFormatter()

    formatter.ingest(delta: """
      escaped block:
      \\`\\`\\`
      let a = "Hello world"
      \\`\\`\\`
      non escaped block:
      \\````
      let b = "Hello world"
      \\\\```
      """)

    #expect(formatter.elements.count == 2)
    #expect(formatter.elements[0].asText?.text == """
      escaped block:
      \\`\\`\\`
      let a = "Hello world"
      \\`\\`\\`
      non escaped block:
      \\`
      """)
    #expect(formatter.elements[1].asCodeBlock?.content == "let b = \"Hello world\"\n\\\\")
  }

  @Test("Many small chunks")
  func test_smallChunks() throws {
    var deltas = [
      "```",
      "swift",
      "\n",
      "//",
      " This",
    ]
    let formatter = TextFormatter()
    while deltas.count > 0 {
      formatter.ingest(delta: deltas.popFirst())
    }
    #expect(formatter.elements.count == 1)
    let codeBlock = try #require(formatter.elements.first?.asCodeBlock)
    #expect(codeBlock.content == """
      // This
      """)
    #expect(codeBlock.language == "swift")
  }

  @Test("Many small chunks")
  func test_manysmallChunks() throws {
    // swiftformat:disable wrap
    // swiftformat:disable wrapArguments
    var deltas = ["```", "swift", "\n", "//", " This", " function", " calculates", " the", " Fibonacci", " number", " at", " a", " specified", " position", "\n", "func", " fibonacci", "(_", " n", ":", " Int", ")", " ->", " Int", " {\n", "   ", " //", " Handle", " the", " base", " cases", "\n", "   ", " if", " n", " <=", " ", "1", " {\n", "       ", " return", " n", "\n", "   ", " }\n", "   ", " //", " Recursive", " call", ":", " sum", " of", " the", " two", " preceding", " numbers", "\n", "   ", " return", " fibonacci", "(n", " -", " ", "1", ")", " +", " fibonacci", "(n", " -", " ", "2", ")\n", "}\n\n//", " Example", " usage", ":\n", "let", " position", " =", " ", "5", "\n", "let", " result", " =", " fibonacci", "(position", ")", " //", " This", " will", " return", " ", "5", ",", " as", " the", " Fibonacci", " sequence", " is", " ", "0", ",", " ", "1", ",", " ", "1", ",", " ", "2", ",", " ", "3", ",", " ", "5", "...\n", "print", "(\"", "F", "ibonacci", " number", " at", " position", " \\(", "position", ")", " is", " \\(", "result", ")\")\n", "``", "`\n\n", "The", " `", "f", "ibonacci", "`", " function", " calculates", " the", " Fibonacci", " number", " at", " a", " specified", " position", " (", "n", ").", " The", " Fibonacci", " sequence", " starts", " with", " ", "0", " and", " ", "1", ",", " and", " each", " subsequent", " number", " is", " the", " sum", " of", " the", " two", " preceding", " numbers", ".", "\n\n", "###", " Explanation", ":\n", "1", ".", " **", "Base", " Cases", ":**", " The", " function", " first", " checks", " if", " `", "n", "`", " is", " less", " than", " or", " equal", " to", " ", "1", ".", " If", " it", " is", ",", " it", " simply", " returns", " `", "n", "`", " because", " the", " first", " two", " Fibonacci", " numbers", " are", " `", "0", "`", " (", "when", " n", "=", "0", ")", " and", " `", "1", "`", " (", "when", " n", "=", "1", ").\n", "\n", "2", ".", " **", "Recursive", " Calls", ":**", " For", " all", " other", " values", " of", " `", "n", "`,", " the", " function", " calls", " itself", " recursively", " to", " compute", " the", " Fibonacci", " number", " by", " summ", "ing", " the", " Fibonacci", " numbers", " at", " positions", " `", "n", "-", "1", "`", " and", " `", "n", "-", "2", "`.", "\n\n", "This", " recursive", " approach", " is", " straightforward", " but", " can", " be", " inefficient", " for", " larger", " values", " of", " `", "n", "`", " due", " to", " repeated", " calculations", ".", " For", " those", " cases", ",", " iterative", " or", " memo", "ization", " techniques", " can", " be", " more", " efficient", "."]
    let formatter = TextFormatter()
    while deltas.count > 0 {
      formatter.ingest(delta: deltas.popFirst())
    }
    #expect(formatter.elements.count == 2)
    #expect(formatter.elements.first?.asCodeBlock?.content == """
      // This function calculates the Fibonacci number at a specified position
      func fibonacci(_ n: Int) -> Int {
          // Handle the base cases
          if n <= 1 {
              return n
          }
          // Recursive call: sum of the two preceding numbers
          return fibonacci(n - 1) + fibonacci(n - 2)
      }

      // Example usage:
      let position = 5
      let result = fibonacci(position) // This will return 5, as the Fibonacci sequence is 0, 1, 1, 2, 3, 5...
      print("Fibonacci number at position \\(position) is \\(result)")
      """)
    #expect(formatter.elements.first?.asCodeBlock?.language == "swift")
    #expect(formatter.elements.last?.asText?.text == """
      The `fibonacci` function calculates the Fibonacci number at a specified position (n). The Fibonacci sequence starts with 0 and 1, and each subsequent number is the sum of the two preceding numbers.

      ### Explanation:
      1. **Base Cases:** The function first checks if `n` is less than or equal to 1. If it is, it simply returns `n` because the first two Fibonacci numbers are `0` (when n=0) and `1` (when n=1).

      2. **Recursive Calls:** For all other values of `n`, the function calls itself recursively to compute the Fibonacci number by summing the Fibonacci numbers at positions `n-1` and `n-2`.

      This recursive approach is straightforward but can be inefficient for larger values of `n` due to repeated calculations. For those cases, iterative or memoization techniques can be more efficient.
      """)
  }

}

extension Array {
  mutating func popFirst() -> Element {
    remove(at: 0)
  }
}

extension TextFormatter {
  convenience init() {
    self.init(projectRoot: URL(filePath: "/"))
  }
}
