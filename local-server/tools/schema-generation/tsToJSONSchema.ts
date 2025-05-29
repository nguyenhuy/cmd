import tsj from "ts-json-schema-generator"
import fs from "fs"
import { dirname } from "path"

export const generateJSONSchemas = (params: { path: string }): { name: string; schema: tsj.Schema }[] => {
	const files = fs.readdirSync(params.path)
	return files.map((file) => {
		const filePath = `${params.path}/${file}`
		const schema = generateJSONSchema({ path: filePath })
		const name = file.split(".")[0]
		return { name, schema }
	})
}

export const generateJSONSchema = (params: { path: string } | { content: string }): tsj.Schema => {
	let config: tsj.Config
	if ("path" in params) {
		config = {
			path: params.path,
			tsconfig: "./tsconfig.json",
			type: "*",
		}
	} else {
		const path = "./tmp/schema.ts"
		fs.mkdirSync(dirname(path), { recursive: true })
		fs.writeFileSync(path, params.content)
		config = {
			path,
			tsconfig: "./tsconfig.json",
			type: "*",
		}
	}
	const schema = tsj.createGenerator(config).createSchema(config.type)
	if ("content" in params && config.path) {
		fs.unlinkSync(config.path)
	}
	return schema
}
