import http from "http"
import { argv } from "process"

// Get port from command line arguments
const portArg = argv.indexOf("--port")
const port = portArg !== -1 ? parseInt(argv[portArg + 1]) : 3000 // Default to 3000 if no port specified

function makeRequestAndProcessChunks(url: string) {
	const data = {
		messages: [{ role: "user", content: "Hello. Generate a poem in 100 words" }],
	}
	const dataString = JSON.stringify(data)

	const options = {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			"Content-Length": dataString.length,
		},
	}

	const req = http.request(url, options, (res) => {
		res.on("data", (chunk: Buffer | string) => {
			// Process the chunk of data here
			console.log("Received chunk:", chunk.toString(), typeof chunk)
		})

		res.on("end", () => {
			console.log("Request complete")
		})

		res.on("error", (err) => {
			console.error("Error:", err)
		})
	})

	req.write(dataString)
	req.end()
}

makeRequestAndProcessChunks(`http://localhost:${port}/sendMessage`)
