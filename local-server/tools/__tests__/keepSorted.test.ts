import { keepSorted } from "../keepSorted"

describe("keepSorted", () => {
	it("should sort simple string arrays", () => {
		const input = `const array = [
        "zebra",
        "apple",
        "banana"
      ]`

		const expected = `const array = [
"apple",
"banana",
"zebra",
]`

		expect(keepSorted(input, { line: 1 })).toBe(expected)
	})
	it("keeps comments above the commented line, and `Keep sorted` on top", () => {
		const input = `const array = [
        // Keep sorted
        "zebra",
        "apple",
        // Good healthy food
        "banana"
      ]`

		const expected = `const array = [
        // Keep sorted
"apple",
// Good healthy food
        "banana",
"zebra",
]`

		expect(keepSorted(input, { line: 2 })).toBe(expected)
	})

	it("should handle items with parentheses", () => {
		const input = `const array = [
            require("zebra", "apple"),
            require("apple", "banana"),
            require("banana", "zebra")
          ]`

		const expected = `const array = [
require("apple", "banana"),
require("banana", "zebra"),
require("zebra", "apple"),
]`

		expect(keepSorted(input, { line: 1 })).toBe(expected)
	})

	it("should preserve content before and after the array", () => {
		const input = `// Header comment
      const array = [
            "zebra",
            "apple",
            "banana",
          ];
      // Footer comment`

		const expected = `// Header comment
      const array = [
"apple",
"banana",
"zebra",
];
      // Footer comment`

		expect(keepSorted(input, { line: 2 })).toBe(expected)
	})

	it("should handle empty arrays", () => {
		const input = `const array = [
        ]`

		expect(keepSorted(input, { line: 1 })).toBe(`const array = [
]`)
	})

	it("should handle arrays with a single item", () => {
		const input = `const array = [
            "apple",
          ]`

		expect(keepSorted(input, { line: 1 })).toBe(`const array = [
"apple",
]`)
	})

	it("works with a custom sort key", () => {
		const input = `const array = [
            .product(name: "apple", source: "b/apple.ts"),
            .product(name: "banana", source: "c/banana.ts"),
            .product(name: "zebra", source: "a/zebra.ts"),
          ]`

		expect(keepSorted(input, { line: 1 }, (item) => item.split("source:")[1])).toBe(`const array = [
.product(name: "zebra", source: "a/zebra.ts"),
.product(name: "apple", source: "b/apple.ts"),
.product(name: "banana", source: "c/banana.ts"),
]`)
	})
})
