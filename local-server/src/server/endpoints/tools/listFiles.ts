import { Request, Response, Router } from "express"
import fs from "fs"
import { ListFilesToolOutput, ListFilesToolInput } from "../../schemas/listFilesSchema"
import { UserFacingError } from "../../errors"
import { resolve } from "path"
import { listFiles } from "@/services/glob/list-files"

export const registerEndpoint = (router: Router) => {
	router.post("/listFiles", async (req: Request, res: Response) => {
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
		const { path, recursive, projectRoot, limit } = body
		const filePaths = await listFiles({
			dirPath: resolve(projectRoot, path),
			recursive: recursive ?? false,
			limit: limit || 100,
			breadthFirstSearch: body.breadthFirstSearch ?? false,
		})

		const filesWithMedatata = filePaths.map(({ path, isTruncated }) => {
			const metadata = fs.statSync(path)
			return {
				path: path,
				isFile: metadata.isFile(),
				isDirectory: metadata.isDirectory(),
				hasMoreContent: isTruncated,
				isSymlink: metadata.isSymbolicLink(),
				byteSize: metadata.size,
				permissions: fileModeToString(metadata.mode),
				createdAt: metadata.birthtime,
				modifiedAt: metadata.mtime,
			}
		})

		const result: ListFilesToolOutput = { files: filesWithMedatata }
		res.json(result)
	})
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
