// To read a streamed message from OpenAI, you can use this script with
// pbpaste | yarn tsx ./tools/parseOpenAIResponse.ts

interface ToolCall {
	index: number
	id?: string
	type?: string
	function?: {
		name?: string
		arguments?: string | Record<string, unknown>
	}
}

interface Delta {
	role?: string
	content?: string
	tool_calls?: ToolCall[]
}

interface Choice {
	index: number
	delta: Delta
}

interface StreamChunk {
	id: string
	choices: Choice[]
	created: number
	model: string
	object: string
}

interface PingMessage {
	type: string
}

// Define a more specific type for the internal tool calls storage
interface InternalToolCall {
	index: number
	id: string
	type: string
	function: {
		name: string
		arguments: string // Always string during collection phase
	}
}

function extractContentFromStream(inputText: string): { text: string; toolCalls: ToolCall[] } {
	// Split the input into lines
	const lines = inputText.trim().split("\n")

	// Initialize variables
	let currentText = ""
	const toolCalls: { [key: string]: InternalToolCall } = {}

	// Process each line
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i]

		// Skip empty lines
		if (!line.trim()) continue

		// Skip ping messages
		if (line.includes('"type": "ping"')) continue

		// Process data lines
		if (line.startsWith("data:")) {
			try {
				// Extract the JSON data
				const jsonStr = line.slice(5).trim() // Remove 'data: ' prefix

				// Skip ping lines with different format
				if (jsonStr.includes(": ping -")) continue

				const data = JSON.parse(jsonStr) as StreamChunk | PingMessage

				// Skip ping messages
				if ("type" in data && data.type === "ping") continue

				// Process content
				if ("choices" in data && data.choices.length > 0) {
					const delta = data.choices[0].delta

					// Extract text content
					if (delta.content) {
						currentText += delta.content
					}

					// Extract tool calls
					if (delta.tool_calls && delta.tool_calls.length > 0) {
						for (const toolCall of delta.tool_calls) {
							const index = toolCall.index

							// Initialize tool call if not exists
							if (!toolCalls[index]) {
								toolCalls[index] = {
									index,
									id: toolCall.id || "",
									type: toolCall.type || "",
									function: {
										name: toolCall.function?.name || "",
										arguments: "",
									},
								}
							}

							// Update tool call data
							if (toolCall.id) toolCalls[index].id = toolCall.id
							if (toolCall.type) toolCalls[index].type = toolCall.type
							if (toolCall.function?.name) toolCalls[index].function.name = toolCall.function.name
							if (toolCall.function?.arguments) {
								// Safely concatenate string arguments
								toolCalls[index].function.arguments += toolCall.function.arguments
							}
						}
					}
				}
			} catch {
				// Skip invalid JSON
				continue
			}
		}
	}

	// Convert tool calls object to array and parse arguments
	const toolCallsArray = Object.values(toolCalls).map((tool) => {
		const result: ToolCall = {
			index: tool.index,
			id: tool.id,
			type: tool.type,
			function: {
				name: tool.function.name,
			},
		}

		// Try to parse the arguments as JSON
		if (tool.function.arguments) {
			try {
				result.function!.arguments = JSON.parse(tool.function.arguments)
			} catch {
				// If parsing fails, keep as string
				result.function!.arguments = tool.function.arguments
			}
		}

		return result
	})

	return { text: currentText, toolCalls: toolCallsArray }
}

// Read from stdin if no file is provided
// Using a different function name to avoid conflict with parseAnthropicResponse.ts
async function processOpenAIStream() {
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

	// Extract and print the content
	const extractedContent = extractContentFromStream(inputText)
	console.log(JSON.stringify(extractedContent, null, 2))
}

processOpenAIStream().catch(console.error)
