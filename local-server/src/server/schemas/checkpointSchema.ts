export interface CreateCheckpointRequestParams {
	// The path to the directory containing the project for which the checkpoint will be created.
	projectRoot: string
	taskId: string
	message: string
}

export interface CreateCheckpointResponseParams {
	commitSha: string
}

export interface RestoreCheckpointRequestParams {
	projectRoot: string
	taskId: string
	commitSha: string
}

export interface RestoreCheckpointResponseParams {
	commitSha: string
}
