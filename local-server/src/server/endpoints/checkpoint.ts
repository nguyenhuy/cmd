import { Request, Response, Router } from "express"
import { logError, logInfo } from "../../logger"
import { addUserFacingError, UserFacingError } from "../errors"
import { RepoPerTaskCheckpointService } from "@/services/checkpoints"
import {
	CreateCheckpointRequestParams,
	CreateCheckpointResponseParams,
	RestoreCheckpointRequestParams,
	RestoreCheckpointResponseParams,
} from "../schemas/checkpointSchema"
import { homedir } from "os"

const checkpointServices: { [key: string]: RepoPerTaskCheckpointService } = {}

const getCheckpointService = async ({
	taskId,
	workspaceDir,
}: {
	taskId: string
	workspaceDir: string
}): Promise<RepoPerTaskCheckpointService> => {
	const id = `${taskId}-${workspaceDir}`
	if (checkpointServices[id]) {
		return checkpointServices[id]
	}

	const service = RepoPerTaskCheckpointService.create({
		taskId,
		workspaceDir,
		shadowDir: `${homedir()}/.cmd/command/checkpoints/`,
		log: (message) => {
			logInfo(message)
		},
	})
	await service.initShadowGit()
	checkpointServices[id] = service
	return service
}

const registerCreateCheckpointEndpoint = (router: Router) => {
	router.post("/checkpoint/create", async (req: Request, res: Response) => {
		// Input validation
		if (
			typeof req.body?.taskId !== "string" ||
			typeof req.body?.projectRoot !== "string" ||
			typeof req.body?.message !== "string"
		) {
			throw new UserFacingError({
				message: "Request body is missing required fields",
				statusCode: 400,
			})
		}

		try {
			const body = req.body as CreateCheckpointRequestParams
			const service = await getCheckpointService({
				taskId: body.taskId,
				workspaceDir: body.projectRoot,
			})
			const checkpointInfo = await service.saveCheckpoint(body.message)
			const response: CreateCheckpointResponseParams = {
				commitSha: checkpointInfo?.commit || (await service.currentGitSha()),
			}
			res.json(response)
		} catch (error) {
			logInfo("Request body that led to error:\n\n" + JSON.stringify(req.body, null, 2) + error)
			logError(error)

			throw addUserFacingError(error, "Failed to create checkpoint.")
		}
	})
}

const registerRestoreCheckpointEndpoint = (router: Router) => {
	router.post("/checkpoint/restore", async (req: Request, res: Response) => {
		// Input validation
		if (
			typeof req.body?.taskId !== "string" ||
			typeof req.body?.projectRoot !== "string" ||
			typeof req.body?.commitSha !== "string"
		) {
			throw new UserFacingError({
				message: "Request body is missing required fields",
				statusCode: 400,
			})
		}

		try {
			const body = req.body as RestoreCheckpointRequestParams
			const service = await getCheckpointService({
				taskId: body.taskId,
				workspaceDir: body.projectRoot,
			})
			await service.restoreCheckpoint(body.commitSha)
			const response: RestoreCheckpointResponseParams = {
				commitSha: body.commitSha,
			}
			res.json(response)
		} catch (error) {
			logInfo("Request body that led to error:\n\n" + JSON.stringify(req.body, null, 2))
			logError(error)

			throw addUserFacingError(error, "Failed to restore checkpoint.")
		}
	})
}

export const registerEndpoints = (router: Router) => {
	registerCreateCheckpointEndpoint(router)
	registerRestoreCheckpointEndpoint(router)
}
