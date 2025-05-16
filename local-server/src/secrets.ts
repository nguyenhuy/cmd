import fs from "fs"
import path from "path"
import { logError } from "./logger"

type Secrets = {
	ANTHROPIC_API_KEY?: string
	OPENAI_API_KEY?: string
}

const loadSecrets = (): Secrets => {
	const secretsPath = path.join(__dirname, "secrets.json")

	if (!fs.existsSync(secretsPath)) {
		return {}
	}

	try {
		const secrets = fs.readFileSync(secretsPath, "utf8")
		return JSON.parse(secrets) as Secrets
	} catch (error) {
		logError(error)
		return {}
	}
}

export default loadSecrets
