import { describe, expect, beforeEach, jest, afterEach } from "@jest/globals"
import Router from "express-promise-router"
import express from "express"
import request from "supertest"
import { registerEndpoints } from "../checkpoint"
import { RepoPerTaskCheckpointService } from "@/services/checkpoints"
import { UserFacingError } from "../../errors"

// Create a complete mock service that extends ShadowCheckpointService
const mockService = {
	// Mock methods
	// @ts-expect-error - Jest mock typing issues with mockResolvedValue
	initShadowGit: jest.fn().mockResolvedValue(undefined),
	// @ts-expect-error - Jest mock typing issues with mockResolvedValue
	saveCheckpoint: jest.fn().mockResolvedValue({ commit: "mock-commit-sha" }),
	// @ts-expect-error - Jest mock typing issues with mockResolvedValue
	restoreCheckpoint: jest.fn().mockResolvedValue(undefined),

	// Add any other properties or methods that might be used
	taskId: "mock-task-id",
	checkpointsDir: "/mock/checkpoints/dir",
	workspaceDir: "/mock/workspace/dir",
	dotGitDir: "/mock/checkpoints/dir/.git",
	log: jest.fn(),
	baseHash: "mock-base-hash",
	isInitialized: true,
	_checkpoints: [],
	emit: jest.fn(),
	on: jest.fn(),
	off: jest.fn(),
	once: jest.fn(),
}

// @ts-expect-error - Jest mock typing issues with mockImplementation
// Mock the RepoPerTaskCheckpointService
jest.spyOn(RepoPerTaskCheckpointService, "create").mockImplementation(() => {
	return mockService
})

describe("Checkpoint Endpoints", () => {
	let app: express.Application
	let mockCheckpointService: typeof mockService

	beforeEach(() => {
		// Create Express app
		app = express()
		app.use(express.json())

		// Register the endpoints
		const router = Router()
		registerEndpoints(router)
		app.use(router)

		// Reset mock implementations
		mockCheckpointService = mockService
		mockCheckpointService.initShadowGit.mockClear()
		mockCheckpointService.saveCheckpoint.mockClear()
		mockCheckpointService.restoreCheckpoint.mockClear()
	})

	afterEach(() => {
		jest.clearAllMocks()
	})

	describe("POST /checkpoint/create", () => {
		it("creates a checkpoint successfully", async () => {
			const response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})

			expect(response.status).toBe(200)
			expect(response.body).toEqual({
				commitSha: "mock-commit-sha",
			})
			expect(RepoPerTaskCheckpointService.create).toHaveBeenCalledWith({
				taskId: "test-task-id",
				workspaceDir: "/test/workspace",
				shadowDir: "/tmp/command/checkpoints/",
				log: expect.any(Function),
			})
			expect(mockCheckpointService.initShadowGit).toHaveBeenCalled()
			expect(mockCheckpointService.saveCheckpoint).toHaveBeenCalledWith("Test checkpoint")
		})

		it("returns 400 if body is missing", async () => {
			const response = await request(app).post("/checkpoint/create").send()

			expect(response.status).toBe(400)
		})

		it("returns 400 if required parameters are missing", async () => {
			// Missing taskId
			let response = await request(app).post("/checkpoint/create").send({
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})

			expect(response.status).toBe(400)

			// Missing workspaceDir
			response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id",
				message: "Test checkpoint",
			})

			expect(response.status).toBe(400)

			// Missing message
			response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
			})

			expect(response.status).toBe(400)
		})

		it("handles service errors", async () => {
			// @ts-expect-error - Jest mock typing issues with mockRejectedValueOnce
			mockCheckpointService.saveCheckpoint.mockRejectedValueOnce(new Error("Service error"))

			const response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})

			expect(response.status).toBe(500)
		})

		it("handles specific user-facing errors", async () => {
			mockCheckpointService.saveCheckpoint.mockRejectedValueOnce(
				// @ts-expect-error - UserFacingError type issues
				new UserFacingError({
					message: "Custom error message",
					statusCode: 403,
				}),
			)

			const response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})

			expect(response.status).toBe(403)
		})
	})

	describe("Service caching", () => {
		it("uses a cached service for the same taskId", async () => {
			// First call with the new task id creates a new checkpoint service
			const response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id-123",
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})
			expect(response.status).toBe(200)

			expect(RepoPerTaskCheckpointService.create).toHaveBeenCalledWith({
				taskId: "test-task-id-123",
				workspaceDir: "/test/workspace",
				shadowDir: "/tmp/command/checkpoints/",
				log: expect.any(Function),
			})
			expect(mockCheckpointService.initShadowGit).toHaveBeenCalled()
			expect(mockCheckpointService.saveCheckpoint).toHaveBeenCalledWith("Test checkpoint")

			// Second call with the same task id uses the cached checkpoint service
			const response2 = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id-123",
				projectRoot: "/test/workspace",
				message: "Test checkpoint 2",
			})
			expect(response2.status).toBe(200)
			expect(RepoPerTaskCheckpointService.create).toHaveBeenCalledTimes(1)
			expect(mockCheckpointService.initShadowGit).toHaveBeenCalledTimes(1)
			expect(mockCheckpointService.saveCheckpoint).toHaveBeenCalledWith("Test checkpoint 2")
		})

		it("creates a new service for a different taskId", async () => {
			// First call with the new task id creates a new checkpoint service
			const response = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id-456",
				projectRoot: "/test/workspace",
				message: "Test checkpoint",
			})
			expect(response.status).toBe(200)

			expect(RepoPerTaskCheckpointService.create).toHaveBeenCalledWith({
				taskId: "test-task-id-456",
				workspaceDir: "/test/workspace",
				shadowDir: "/tmp/command/checkpoints/",
				log: expect.any(Function),
			})
			expect(mockCheckpointService.initShadowGit).toHaveBeenCalled()
			expect(mockCheckpointService.saveCheckpoint).toHaveBeenCalledWith("Test checkpoint")

			// Second call with the same task id uses the cached checkpoint service
			const response2 = await request(app).post("/checkpoint/create").send({
				taskId: "test-task-id-789",
				projectRoot: "/test/workspace",
				message: "Test checkpoint 2",
			})
			expect(response2.status).toBe(200)
			expect(RepoPerTaskCheckpointService.create).toHaveBeenCalledTimes(2)
			expect(mockCheckpointService.initShadowGit).toHaveBeenCalledTimes(2)
			expect(mockCheckpointService.saveCheckpoint).toHaveBeenCalledWith("Test checkpoint 2")
		})
	})

	describe("POST /checkpoint/restore", () => {
		it("restores a checkpoint successfully", async () => {
			const response = await request(app).post("/checkpoint/restore").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				commitSha: "test-commit-sha",
			})

			expect(response.status).toBe(200)
			expect(response.body).toEqual({
				commitSha: "test-commit-sha",
			})
			expect(mockCheckpointService.restoreCheckpoint).toHaveBeenCalledWith("test-commit-sha")
		})

		it("returns 400 if body is missing", async () => {
			const response = await request(app).post("/checkpoint/restore").send()

			expect(response.status).toBe(400)
		})

		it("returns 400 if required parameters are missing", async () => {
			// Missing taskId
			let response = await request(app).post("/checkpoint/restore").send({
				projectRoot: "/test/workspace",
				commitSha: "test-commit-sha",
			})

			expect(response.status).toBe(400)

			// Missing workspaceDir
			response = await request(app).post("/checkpoint/restore").send({
				taskId: "test-task-id",
				commitSha: "test-commit-sha",
			})

			expect(response.status).toBe(400)

			// Missing commitSha
			response = await request(app).post("/checkpoint/restore").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
			})

			expect(response.status).toBe(400)
		})

		it("handles service errors", async () => {
			// @ts-expect-error - Jest mock typing issues with mockRejectedValueOnce
			mockCheckpointService.restoreCheckpoint.mockRejectedValueOnce(new Error("Service error"))

			const response = await request(app).post("/checkpoint/restore").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				commitSha: "test-commit-sha",
			})

			expect(response.status).toBe(500)
		})

		it("handles specific user-facing errors", async () => {
			mockCheckpointService.restoreCheckpoint.mockRejectedValueOnce(
				// @ts-expect-error - UserFacingError type issues
				new UserFacingError({
					message: "Custom error message",
					statusCode: 403,
				}),
			)

			const response = await request(app).post("/checkpoint/restore").send({
				taskId: "test-task-id",
				projectRoot: "/test/workspace",
				commitSha: "test-commit-sha",
			})

			expect(response.status).toBe(403)
		})
	})
})
