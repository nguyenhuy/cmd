// copied from https://github.com/RooVetGit/Roo-Code/blob/4f727142ae6f85d04949ac9022c1e38d71c8c63d

import { CommitResult } from "simple-git"

export type CheckpointResult = Partial<CommitResult> & Pick<CommitResult, "commit">

export type CheckpointDiff = {
	paths: {
		relative: string
		absolute: string
	}
	content: {
		before: string
		after: string
	}
}

export interface CheckpointServiceOptions {
	taskId: string
	workspaceDir: string
	shadowDir: string // globalStorageUri.fsPath

	log?: (message: string) => void
}

export interface Checkpoint {
	type: "checkpoint"
	isFirst: boolean
	fromHash: string
	toHash: string
	duration: number
}

export interface Restore {
	type: "restore"
	commitHash: string
	duration: number
}

export interface CheckpointError {
	type: "error"
	error: Error
}

export interface CheckpointEventMap {
	initialize: { type: "initialize"; workspaceDir: string; baseHash: string; created: boolean; duration: number }
	checkpoint: Checkpoint
	restore: Restore
	error: CheckpointError
}
