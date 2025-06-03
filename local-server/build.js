import * as esbuild from "esbuild"
import esbuildPluginTsc from "esbuild-plugin-tsc"
import crypto from "crypto"
import fs from "fs/promises"
import { execSync } from "child_process"

const buildOptions = {
	entryPoints: ["src/main.ts"],
	outfile: "dist/main.bundle.js",
	bundle: true,
	plugins: [
		esbuildPluginTsc({
			tsconfigPath: "./tsconfig.json",
			force: true,
		}),
	],
	sourcemap: true,
	platform: "node",
	// While this seems to be the desired setting, this doesn't work.
	// See https://github.com/evanw/esbuild/issues/1921 and https://github.com/evanw/esbuild/issues/3324#issuecomment-2215644754
	// format: 'esm',
	minify: true,
}

if (process.env.NODE_ENV === "production") {
	buildOptions.define = { "process.env.NODE_ENV": '"production"' }
} else {
	buildOptions.define = { "process.env.NODE_ENV": '"development"' }
}

// Function to compute and save SHA256 hash
export async function computeAndSaveHash() {
	let fileBuffer = ""
	try {
		fileBuffer = await fs.readFile("./dist/main.bundle.js")
	} catch (error) {
		// the bundle file doesn't exist yet. This is ok.
	}
	const hashSum = crypto.createHash("sha256")
	hashSum.update(fileBuffer)
	hashSum.update(`${process.env.NODE_ENV}`)
	const hex = hashSum.digest("hex")
	await fs.writeFile("./build.sha256", hex)
	return hex
}



// Function to compute and save build file size.
export async function computeAndSaveBuildFileSize() {
	let fileBuffer = ""
	try {
		fileBuffer = await fs.readFile("./dist/main.bundle.js")
	} catch (error) {
		// the bundle file doesn't exist yet. This is ok.
		return;
	}
	
	// buid file size in MB
	const stats = await fs.stat("./dist/main.bundle.js").catch(() => ({ size: 0 }))
	const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2)

	// compressed  file using process
	// Compressed file size in MB
	execSync(`gzip -k ./dist/main.bundle.js -f`, { stdio: "inherit" });
	const compressedStats = await fs.stat("./dist/main.bundle.js.gz").catch(() => ({ size: 0 }))
	const compressedSizeInMB = (compressedStats.size / (1024 * 1024)).toFixed(2)

	await fs.writeFile("./build.size", JSON.stringify({
		size: `${sizeInMB}MB`,
		compressedSize: `${compressedSizeInMB}MB`,
	}, null, 2));
}

await computeAndSaveHash()
await computeAndSaveBuildFileSize()

const plugins = [
	{
		name: "post-build-plugin",
		setup(build) {
			let count = 0
			let t0 = Date.now()
			build.onStart(() => {
				t0 = Date.now()
			})
			build.onEnd(async (result) => {
				if (result.errors.length > 0) {
					console.error("build failed:", result.errors)
				} else {
					await computeAndSaveBuildFileSize()
					let newHash = await computeAndSaveHash()
					if (count++ === 0) console.log(`build completed in ${Date.now() - t0}ms (${newHash})`)
					else console.log(`re-build completed in ${Date.now() - t0}ms (${newHash})`)
				}
			})
		},
	},
]

export const ctx = await esbuild.context({ ...buildOptions, plugins })

// Check if --watch flag is present in process arguments
if (process.argv.includes("--watch")) {
	// Set up watch mode with hash computation after each rebuild
	ctx.watch()
} else {
	ctx.rebuild()
	ctx.dispose()
}
