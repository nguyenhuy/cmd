// To read a streamed message from Anthropic, you can use this script with
// pbpaste | yarn tsx ./tools/parseAnthropicResponse.ts

interface StreamDelta {
	type: string
	text?: string
	partial_json?: string
}

interface InputJsonDelta {
	type: "input_json_delta"
	partial_json: string
}

interface StreamData {
	type: string
	delta: StreamDelta
	index?: number
}

interface ContentBlock {
	type: string
	id?: string
	name?: string
	input?: unknown
}

interface ContentBlockStart {
	type: string
	index: number
	content_block: ContentBlock
}

interface AnthropicToolCall {
	name?: string
	parameters?: unknown
	raw?: string
}

function extractTextFromStream(inputText: string): { text: string; tool: AnthropicToolCall | null } {
	// Split the input into lines
	const lines = inputText.trim().split("\n")

	// Initialize variables
	let currentText = ""
	let currentTool = ""
	let toolName = ""
	let toolId = ""

	// Process each line
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i]

		// Handle content_block_start events for tool_use
		if (line.startsWith("event: content_block_start")) {
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					const jsonStr = dataLine.slice(5).trim()
					const data = JSON.parse(jsonStr) as ContentBlockStart

					if (data.content_block?.type === "tool_use") {
						toolName = data.content_block.name || ""
						toolId = data.content_block.id || ""
					}
				} catch {
					// Skip invalid JSON
					continue
				}
			}
		}

		// Handle content_block_delta events
		else if (line.startsWith("event: content_block_delta")) {
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					const jsonStr = dataLine.slice(5).trim()
					const data = JSON.parse(jsonStr) as StreamData

					// Extract text from text_delta
					if (data.delta?.text) {
						currentText += data.delta.text
					}
					// Extract tool parameters from partial_json (old format)
					else if (data.delta?.partial_json) {
						currentTool += data.delta.partial_json
					}
					// Extract tool parameters from input_json_delta (new format)
					else if (data.delta && "partial_json" in data.delta && data.delta.type === "input_json_delta") {
						currentTool += (data.delta as InputJsonDelta).partial_json
					}
				} catch {
					// Skip invalid JSON
					continue
				}
			}
		}
	}

	// Parse tool JSON if present, otherwise return null
	let toolCall: AnthropicToolCall | null = null
	if (toolName || currentTool.trim()) {
		try {
			if (toolName && currentTool.trim()) {
				// New format: we have tool name from content_block_start and parameters from input_json_delta
				const parsedParameters = JSON.parse(currentTool)
				toolCall = {
					name: toolName,
					parameters: parsedParameters,
				}
			} else if (currentTool.trim()) {
				// Old format: everything is in partial_json
				const parsedTool = JSON.parse(currentTool)
				toolCall = {
					name: parsedTool.name,
					parameters: parsedTool.parameters,
				}
			}
		} catch {
			// If tool JSON is malformed, return the raw string
			toolCall = {
				raw: currentTool,
			}
		}
	}

	return { text: currentText, tool: toolCall }
}

// Export the function for testing
export { extractTextFromStream }

// Read from stdin if no file is provided
async function main() {
	let inputText: string

	if (process.argv.length > 2) {
		// Read from file
		const fs = await import("fs/promises")
		inputText = await fs.readFile(process.argv[2], "utf-8")
	} else {
		// Read from stdin
		inputText = await new Promise<string>((resolve) => {
			let data = ""
			process.stdin.on("data", (chunk) => {
				data += chunk
			})
			process.stdin.on("end", () => {
				resolve(data)
			})
		})
	}

	// Extract and print the text
	const extractedText = extractTextFromStream(inputText)
	console.log(JSON.stringify(extractedText, null, 2))
}

main().catch(console.error)
