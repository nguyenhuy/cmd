import { globby, Options } from "globby"
import os from "os"
import * as path from "path"
import { arePathsEqual } from "../../../utils/path"
import { Request, Response, Router } from "express"
import { logInfo } from "../../../logger"
import fs from "fs"
import { ListFilesToolOutput, ListFilesToolInput } from "../../schemas/listFilesSchema"
import { UserFacingError } from "../../errors"
import { resolve } from "path"

export const registerEndpoint = (router: Router) => {
	router.post("/listFiles", async (req: Request, res: Response) => {
		logInfo(`listFiles ${JSON.stringify(req.body)}`)
		if (!req.body || typeof req.body !== "object") {
			throw new UserFacingError({
				message: "No body",
				statusCode: 400,
			})
		}
		const body = req.body as ListFilesToolInput
		if (typeof body.path !== "string") {
			throw new UserFacingError({
				message: "Parameter `path` must be a string",
				statusCode: 400,
			})
		}
		if (typeof body.projectRoot !== "string") {
			throw new UserFacingError({
				message: "Parameter `projectRoot` must be a string",
				statusCode: 400,
			})
		}
		const { path, recursive, projectRoot } = body
		const [filePaths, hasMore] = await listFiles(resolve(projectRoot, path), recursive ?? false, 100)

		const filesWithMedatata = filePaths.map((filePath) => {
			const metadata = fs.statSync(filePath)
			logInfo(
				`metadata ${JSON.stringify({
					filePath,
					...metadata,
				})}`,
			)
			return {
				path: filePath,
				isFile: metadata.isFile(),
				isDirectory: metadata.isDirectory(),
				isSymlink: metadata.isSymbolicLink(),
				byteSize: metadata.size,
				permissions: fileModeToString(metadata.mode),
				createdAt: metadata.birthtime,
				modifiedAt: metadata.mtime,
			}
		})

		logInfo(`listedFiles ${JSON.stringify({ filePaths, hasMore })}`)
		const result: ListFilesToolOutput = { files: filesWithMedatata, hasMore }
		res.json(result)
	})
}

async function listFiles(dirPath: string, recursive: boolean, limit: number): Promise<[string[], boolean]> {
	const absolutePath = path.resolve(dirPath)
	// Do not allow listing files in root or home directory, which cline tends to want to do when the user's prompt is vague.
	const root = process.platform === "win32" ? path.parse(absolutePath).root : "/"
	const isRoot = arePathsEqual(absolutePath, root)
	if (isRoot) {
		return [[root], false]
	}
	const homeDir = os.homedir()
	const isHomeDir = arePathsEqual(absolutePath, homeDir)
	if (isHomeDir) {
		return [[homeDir], false]
	}

	const dirsToIgnore = [
		"node_modules",
		"__pycache__",
		"env",
		"venv",
		"target/dependency",
		"build/dependencies",
		"dist",
		"out",
		"bundle",
		"vendor",
		"tmp",
		"temp",
		"deps",
		"pkg",
		"Pods",
		".*", // '!**/.*' excludes hidden directories, while '!**/.*/**' excludes only their contents. This way we are at least aware of the existence of hidden directories.
	].map((dir) => `**/${dir}/**`)

	const filesToIgnore = [".DS_Store"]

	const options: Options = {
		cwd: dirPath,
		dot: true, // do not ignore hidden files/directories
		absolute: true,
		markDirectories: true, // Append a / on any directories matched (/ is used on windows as well, so dont use path.sep)
		gitignore: recursive, // globby ignores any files that are gitignored
		ignore: recursive ? dirsToIgnore : undefined, // just in case there is no gitignore, we ignore sensible defaults
		onlyFiles: false, // true by default, false means it will list directories on their own too
		suppressErrors: true,
	}

	// * globs all files in one dir, ** globs files in nested directories
	const filePaths = (
		recursive ? await globbyLevelByLevel(limit, options) : (await globby("*", options)).slice(0, limit)
	).filter((filePath) => !filesToIgnore.includes(filePath.split("/").reverse()[0]))

	return [filePaths, filePaths.length >= limit]
}

/*
Breadth-first traversal of directory structure level by level up to a limit:
   - Queue-based approach ensures proper breadth-first traversal
   - Processes directory patterns level by level
   - Captures a representative sample of the directory structure up to the limit
   - Minimizes risk of missing deeply nested files

- Notes:
   - Relies on globby to mark directories with /
   - Potential for loops if symbolic links reference back to parent (we could use followSymlinks: false but that may not be ideal for some projects and it's pointless if they're not using symlinks wrong)
   - Timeout mechanism prevents infinite loops
*/
async function globbyLevelByLevel(limit: number, options?: Options) {
	const results: Set<string> = new Set()
	const queue: string[] = ["*"]

	const globbingProcess = async () => {
		while (queue.length > 0 && results.size < limit) {
			const pattern = queue.shift()!
			const filesAtLevel = await globby(pattern, options)

			for (const file of filesAtLevel) {
				if (results.size >= limit) {
					break
				}
				results.add(file)
				if (file.endsWith("/")) {
					queue.push(`${file}*`)
				}
			}
		}
		return Array.from(results).slice(0, limit)
	}

	// Timeout after 10 seconds and return partial results
	const timeoutPromise = new Promise<string[]>((_, reject) => {
		setTimeout(() => reject(new Error("Globbing timeout")), 10_000)
	})
	try {
		return await Promise.race([globbingProcess(), timeoutPromise])
	} catch {
		console.warn("Globbing timed out, returning partial results")
		return Array.from(results)
	}
}

/**
 * Convert a file mode number to a string of permissions.
 * @param mode - The file mode number.
 * @returns A string of permissions. eg. drwxr-xr-x
 */
const fileModeToString = (mode: number) => {
	// 1. Determine the file type character.
	// You can use the built-in constants in fs.constants, or the Stats methods.
	let typeChar = "-" // default "regular file"
	if ((mode & fs.constants.S_IFDIR) === fs.constants.S_IFDIR) typeChar = "d"
	else if ((mode & fs.constants.S_IFLNK) === fs.constants.S_IFLNK) typeChar = "l"

	// 2. Extract the permission bits for user, group, and others.
	// mode is a 16-bit value, but we only really care about the last 9 bits for permissions.
	const userPermissions = (mode >> 6) & 0o7 // bits 6-8
	const groupPermissions = (mode >> 3) & 0o7 // bits 3-5
	const otherPermissions = (mode >> 0) & 0o7 // bits 0-2

	// 3. Convert numeric permissions into rwx strings.
	function toRwxString(perm) {
		return (perm & 4 ? "r" : "-") + (perm & 2 ? "w" : "-") + (perm & 1 ? "x" : "-")
	}

	return typeChar + toRwxString(userPermissions) + toRwxString(groupPermissions) + toRwxString(otherPermissions)
}
