/**
 * Finds the next occurrence of a delimiter in a string while respecting nested scopes
 * (quotes, parentheses, and square brackets).
 *
 * @param content - The string to search through
 * @param delimiter - The character to search for (e.g. ',' or ']')
 * @param startIndex - The index to start searching from
 * @param initialScopesCount - Initial nesting level (default: 0)
 * @returns The index of the next delimiter, or -1 if not found
 */
const getNextDelimiterIndex = (content: string, delimiter: string, startIndex: number, initialScopesCount = 0) => {
	let inQuotes = false
	let scopesCount = initialScopesCount
	for (let i = startIndex; i < content.length; i++) {
		const char = content[i]

		if (char === '"') {
			inQuotes = !inQuotes
			if (inQuotes) {
				scopesCount++
			} else {
				scopesCount--
			}
		} else if (char === "(") {
			scopesCount++
		} else if (char === ")") {
			scopesCount--
		} else if (char === "[") {
			scopesCount++
		} else if (char === "]") {
			scopesCount--
		}

		if (char === delimiter && scopesCount === 0) {
			return i
		}
	}
	return -1
}

/**
 * Sorts items in a list within a file, preserving comments.
 * This will likely mess up indentation, and is expected to be run before a linter fixes indentation.
 * The list should be enclosed in square brackets and items separated by commas.
 *
 * @param fileContent - The content of the file
 * @param start - Where to start processing the list:
 *                { line: number } - The first line (0 offset) inside the list.
 *                { index: number } - The offset of the first character inside the list
 * @param sortKey - Optional function to transform items before comparison
 * @returns The file content with the list sorted
 */
export const keepSorted = (
	fileContent: string,
	start: { line: number } | { index: number },
	sortKey: (item: string) => string = (item) => item,
): string => {
	const before =
		"line" in start
			? fileContent.split("\n").slice(0, start.line).join("\n")
			: fileContent.slice(0, start.index + 1)
	// if the before content contains a [, we need to start the search from the next line
	const listEnd = getNextDelimiterIndex(fileContent, "]", before.length, 1)

	const after = fileContent.slice(listEnd)

	const list = fileContent.slice(before.length, listEnd + 1)

	let items: string[] = []

	let i = 0
	while (i < list.length) {
		const nextCommaIndex = getNextDelimiterIndex(list, ",", i)
		if (nextCommaIndex === -1) {
			items.push(list.slice(i, list.length - 1).trim())
			break
		}
		items.push(list.slice(i, nextCommaIndex).trim())
		i = nextCommaIndex + 1
	}

	items = items.filter((item) => item !== "")
	const sortedItems = items.sort((a, b) => {
		const ab = [a, b]
			.map((e) =>
				e
					.split("\n")
					.map((line) => line.trim())
					// ignore lines with comments
					.filter((l) => !l.startsWith("//"))
					.join("\n"),
			)
			.map(sortKey)

		return ab[0].localeCompare(ab[1])
	})
	if (sortedItems.length === 0) {
		return before + "\n" + after
	}
	return before + "\n" + sortedItems.join(",\n") + ",\n" + after
}
