// Copyright cmd app, Inc. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

import FileDiffFoundation
import Testing

struct RebaseChangesTests {
  @Test
  func rebaseUnrelatedChanges() throws {
    let initialContent = """
      // 1
      // 2
      // 3
      // 4
      // 5
      """

    let targetContent = """
      // 0 -- new
      // 1
      // 2
      // 3
      // 4
      // 5
      """

    let currentContent = """
      // 1
      // 2
      // 3
      // 4
      // 5
      // 6 -- new
      """

    let mergedContent = try FileDiff.rebaseChange(
      baselineContent: initialContent,
      currentContent: currentContent,
      targetContent: targetContent)
    #expect(mergedContent == """
      // 0 -- new
      // 1
      // 2
      // 3
      // 4
      // 5
      // 6 -- new
      """)
  }

  @Test
  func rebaseConflictingChanges() throws {
    let initialContent = """
      // 1
      // 2
      // 3
      // 4
      // 5
      """

    let targetContent = """
      // 0 -- changed
      // 2
      // 3
      // 4
      // 5
      """

    let currentContent = """
      // -1 -- changed
      // 2
      // 3
      // 4
      // 5
      """

    let mergedContent = try FileDiff.rebaseChange(
      baselineContent: initialContent,
      currentContent: currentContent,
      targetContent: targetContent)
    #expect(mergedContent == """
      <<<<<<< HEAD
      // -1 -- changed
      =======
      // 0 -- changed
      >>>>>>> suggestion
      // 2
      // 3
      // 4
      // 5
      """)
  }

  @Test
  func rebaseConflictingAndUnrelatedChanges() throws {
    let initialContent = """
      // 1
      // 2
      // 3
      // 4
      // 5
      """

    let targetContent = """
      // 0 -- changed
      // 2
      // 3
      // 4
      // 5
      // 6 -- new
      """

    let currentContent = """
      // -1 -- changed
      // 2
      // 3
      // 4
      // 5
      """

    let mergedContent = try FileDiff.rebaseChange(
      baselineContent: initialContent,
      currentContent: currentContent,
      targetContent: targetContent)
    #expect(mergedContent == """
      <<<<<<< HEAD
      // -1 -- changed
      =======
      // 0 -- changed
      >>>>>>> suggestion
      // 2
      // 3
      // 4
      // 5
      // 6 -- new
      """)
  }

  @Test
  func rebaseWithEmptyLinesAndSpecialToken() throws {
    let initialContent = """

      // 1
      <l>

      // 2
      // 3
      // 4
      // 5

      """

    let targetContent = """
      // 0

      // 1
      <l>

      // 2
      // 3
      // 4
      // 5

      """

    let currentContent = """

      // 1
      <l>

      // 2
      // 3
      // 4
      // 5
      // 6

      """

    let mergedContent = try FileDiff.rebaseChange(
      baselineContent: initialContent,
      currentContent: currentContent,
      targetContent: targetContent)
    #expect(mergedContent == """
      // 0

      // 1
      <l>

      // 2
      // 3
      // 4
      // 5
      // 6

      """)
  }
}
