import watch from "node-watch"
import { execSync, spawn } from "child_process"
import { computeAndSaveHash } from "../build.js"
import generateSwiftSchema from "./generateSwiftSchema.js"

watch("./dist/main.bundle.js", { recursive: true }, async function (evt, name) {
	console.log("changed.", name)

	await computeAndSaveHash()

	const child = spawn("yarn", ["copy-to-app"], {
		stdio: "inherit",
		shell: true,
	})

	child.on("error", (error) => {
		console.error(`Error executing command: ${error}`)
	})
})

watch("./src/server/schemas", { recursive: true }, function (evt, name) {
	console.log("changed.", name)
	try {
		generateSwiftSchema()
	} catch (error) {
		console.error(`Error generating Swift schema: ${error as Error}`)
	}
})

watch("../app/modules", { recursive: true }, function (evt, name) {
	const fileName = name.split("/").pop()
	if (fileName === "Package.swift" || fileName === "Module.swift" || !fileName?.endsWith(".swift")) {
		return
	}
	const scriptPath = import.meta.resolve("../../app/cmd.sh").replace("file://", "")
	execSync(`${scriptPath} sync:dependencies`)
})
