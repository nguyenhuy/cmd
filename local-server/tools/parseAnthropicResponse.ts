// To read a streamed message from Anthropic, you can use this script with
// pbpaste | yarn tsx ./tools/parseAnthropicResponse.ts

interface StreamDelta {
	type: string
	text?: string
	partial_json?: string
}

interface StreamData {
	type: string
	delta: StreamDelta
}

function extractTextFromStream(inputText: string): { text: string; tool: string } {
	// Split the input into lines
	const lines = inputText.trim().split("\n")

	// Initialize variables
	let currentText = ""
	let currentTool = ""

	// Process each line
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i]
		if (line.startsWith("event: content_block_delta")) {
			// Get the next line which contains the data
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					// Extract the JSON data
					const jsonStr = dataLine.slice(5).trim() // Remove 'data: ' prefix
					const data = JSON.parse(jsonStr) as StreamData

					// Extract the text from the delta
					if (data.delta?.text) {
						currentText += data.delta.text
					} else if (data.delta?.partial_json) {
						currentTool += data.delta.partial_json
					}
				} catch (error) {
					// Skip invalid JSON
					continue
				}
			}
		}
	}

	return { text: currentText, tool: JSON.parse(currentTool) }
}

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
