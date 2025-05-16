import { Request, Response, Router } from "express"
import { UserFacingError } from "../errors"
import { getIconForFilePath, getIconUrlByName, getIconForDirectoryPath } from "vscode-material-icons"

export const registerEndpoint = (router: Router) => {
	router.post("/icon", async (req: Request, res: Response) => {
		// Input validation
		if (typeof req.body?.path !== "string" || typeof req.body?.type !== "string") {
			throw new UserFacingError({
				message: "Request body is missing required fields",
				statusCode: 400,
			})
		}

		const name = req.body.path.split("/").filter(Boolean).at(-1) ?? ""
		const iconName = req.body.type === "folder" ? getIconForDirectoryPath(name) : getIconForFilePath(name)
		const iconPath = getIconUrlByName(iconName, ".")
		res.json({ iconPath })
	})
}
