import { exec } from "child_process"
import { ConnectionInfo } from "../src/server/server"
import fs from "fs"
import path from "path"
import os from "os"

function execute(command: string): Promise<string> {
	return new Promise((resolve, reject) => {
		exec(command, (error, stdout) => {
			if (error) {
				reject(error)
			} else {
				resolve(stdout)
			}
		})
	})
}

const hotServerReload = async () => {
	// Find on which port the server last started at.
	const connectionInfoFilePath = path.join(
		os.homedir(),
		"Library/Application Support/XCompanion/last-connection-info.json",
	)
	const connectionInfo = JSON.parse(fs.readFileSync(connectionInfoFilePath, "utf8")) as ConnectionInfo
	const port = connectionInfo.port

	try {
		// Find the id of the process running on the port.
		let processInfoString = await execute(`lsof -i :${port} | jc --lsof`)
		let processInfo = JSON.parse(processInfoString) as {
			pid: number
			name: string
		}[]
		if (!processInfo || processInfo.length === 0) {
			console.log(`No process found on port ${port}`)
			return
		}

		const pid = processInfo[0].pid

		// Make sure the process running on that port corresponds to the server to reload.
		processInfoString = await execute(`lsof -p ${pid} | jc --lsof`)
		processInfo = JSON.parse(processInfoString) as {
			pid: number
			name: string
		}[]
		if (!processInfo || processInfo.length === 0) {
			console.log(`No process found on port ${port}`)
			return
		}

		const processName = processInfo[0].name

		if (!processName.includes("/Library/Application Support/XCompanion")) {
			console.log(`Process ${processName} is not a XCompanion process`)
			return
		}

		console.log(`Killing process ${processName} with pid ${pid}`)
		await execute(`kill -9 ${pid}`)
	} catch {
		console.log(`No process found on port ${port}`)
		return
	}

	// The app will restart the server if it dies. No need to do anything here.
}

void hotServerReload()
