import { describe, expect, beforeEach, afterEach } from "@jest/globals"
import express from "express"
import request from "supertest"
import http from "http"
import Router from "express-promise-router"
import errorHandler from "../errorHandler"

describe("Error Handler", () => {
	let app: express.Application
	let server: http.Server

	beforeEach(async () => {
		// Create Express app with error handler
		app = express()
		app.use(express.json())

		const router = Router()

		// Test endpoints that throw different types of errors
		router.get("/test/sync-error", () => {
			throw new Error("Synchronous error")
		})

		router.get("/test/async-error", async () => {
			throw new Error("Asynchronous error")
		})

		router.get("/test/custom-status-error", () => {
			const error = new Error("Custom status error") as Error & { statusCode: number }
			error.statusCode = 418
			throw error
		})

		router.get("/test/404-error", () => {
			const error = new Error("Not found error") as Error & { statusCode: number }
			error.statusCode = 404
			throw error
		})

		router.get("/test/empty-message-error", () => {
			const error = new Error("") as Error
			throw error
		})

		router.get("/test/sse-error", (_, res) => {
			res.setHeader("Content-Type", "text/event-stream")
			res.setHeader("Cache-Control", "no-cache")
			res.setHeader("Connection", "keep-alive")
			throw new Error("SSE error")
		})

		router.get("/test/sse-headers-sent-error", (_, res) => {
			res.setHeader("Content-Type", "text/event-stream")
			res.setHeader("Cache-Control", "no-cache")
			res.setHeader("Connection", "keep-alive")
			res.write('data: {"type":"ping","timestamp":1234}\n\n') // Send some data first
			throw new Error("SSE error after headers sent")
		})

		router.get("/test/headers-sent-error", (_, res) => {
			res.status(200).send("Response already sent")
			throw new Error("Error after headers sent")
		})

		router.get("/test/no-error", (_, res) => {
			res.json({ success: true })
		})

		app.use(router)

		// Add 404 handler
		app.use((req, res, next) => {
			const error = new Error(`Not Found - ${req.originalUrl}`) as Error & { statusCode: number }
			error.statusCode = 404
			next(error)
		})

		// Add error handler (should be last)
		app.use(errorHandler)

		return new Promise<void>((resolve) => {
			server = app.listen(0, () => {
				resolve()
			})
		})
	})

	afterEach(async () => {
		return new Promise<void>((resolve, reject) => {
			if (server) {
				server.close((err) => {
					if (err) {
						reject(err)
					} else {
						resolve()
					}
				})
			} else {
				resolve()
			}
		})
	})

	describe("Synchronous errors", () => {
		it("should catch synchronous errors and return 500 status", async () => {
			const response = await request(app).get("/test/sync-error")

			expect(response.status).toBe(500)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 500,
				message: "Synchronous error",
				stack: {},
			})
		})
	})

	describe("Asynchronous errors", () => {
		it("should catch async errors and return 500 status", async () => {
			const response = await request(app).get("/test/async-error")

			expect(response.status).toBe(500)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 500,
				message: "Asynchronous error",
				stack: {},
			})
		})
	})

	describe("Custom status codes", () => {
		it("should respect custom status codes", async () => {
			const response = await request(app).get("/test/custom-status-error")

			expect(response.status).toBe(418)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 418,
				message: "Custom status error",
				stack: {},
			})
		})

		it("should handle 404 errors", async () => {
			const response = await request(app).get("/test/404-error")

			expect(response.status).toBe(404)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 404,
				message: "Not found error",
				stack: {},
			})
		})
	})

	describe("Empty or missing error messages", () => {
		it("should provide default message for empty error messages", async () => {
			const response = await request(app).get("/test/empty-message-error")

			expect(response.status).toBe(500)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 500,
				message: "Something went wrong",
				stack: {},
			})
		})
	})

	describe("Server-Sent Events (SSE) errors", () => {
		it("should format SSE errors according to SSE protocol", async () => {
			const response = await request(app).get("/test/sse-error")

			expect(response.status).toBe(500)
			expect(response.text).toContain(
				'data: {"type":"error","success":false,"statusCode":500,"message":"SSE error","stack":{}}',
			)
			expect(response.text).toContain("\n\n")
		})

		it("should handle SSE errors when headers are already sent", async () => {
			const response = await request(app).get("/test/sse-headers-sent-error")

			expect(response.status).toBe(200) // Headers were already sent with 200
			expect(response.text).toContain('data: {"type":"ping","timestamp":1234}')
			expect(response.text).toContain(
				'data: {"type":"error","success":false,"statusCode":500,"message":"SSE error after headers sent","stack":{}}',
			)
		})
	})

	describe("Headers already sent scenarios", () => {
		it("should handle errors when headers are already sent", async () => {
			const response = await request(app).get("/test/headers-sent-error")

			// The response should be successful since headers were already sent
			expect(response.status).toBe(200)
			expect(response.text).toBe("Response already sent")
		})
	})

	describe("404 handling", () => {
		it("should handle non-existent routes with 404 error", async () => {
			const response = await request(app).get("/non-existent-route")

			expect(response.status).toBe(404)
			expect(response.body).toEqual({
				type: "error",
				success: false,
				statusCode: 404,
				message: "Not Found - /non-existent-route",
				stack: {},
			})
		})
	})

	describe("Successful requests", () => {
		it("should not interfere with successful requests", async () => {
			const response = await request(app).get("/test/no-error")

			expect(response.status).toBe(200)
			expect(response.body).toEqual({ success: true })
		})
	})

	describe("Development mode stack traces", () => {
		it("should include stack traces in development mode", async () => {
			// Set NODE_ENV to development
			const originalEnv = process.env.NODE_ENV
			process.env.NODE_ENV = "development"

			const response = await request(app).get("/test/sync-error")

			expect(response.status).toBe(500)
			expect(response.body.stack).toBeDefined()
			expect(typeof response.body.stack).toBe("string")
			expect(response.body.stack).toContain("Error: Synchronous error")

			// Restore original NODE_ENV
			process.env.NODE_ENV = originalEnv
		})

		it("should not include stack traces in production mode", async () => {
			// Set NODE_ENV to production
			const originalEnv = process.env.NODE_ENV
			process.env.NODE_ENV = "production"

			const response = await request(app).get("/test/sync-error")

			expect(response.status).toBe(500)
			expect(response.body.stack).toEqual({})

			// Restore original NODE_ENV
			process.env.NODE_ENV = originalEnv
		})
	})
})
