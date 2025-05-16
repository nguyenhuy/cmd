import { Request, Response, NextFunction } from "express"
import { logError } from "../logger"

// Catch all errors during the execution to avoid crashing the server, and return a 500 error instead.
const errorHandler = (err: Error & { statusCode?: number }, req: Request, res: Response, next: NextFunction) => {
	const errStatus = err.statusCode || 500
	const errMsg = err.message || "Something went wrong"

	logError(`Request failed: ${errMsg}`)
	const errorInfo = {
		type: "error",
		success: false,
		statusCode: errStatus,
		message: errMsg,
		stack: process.env.NODE_ENV === "development" ? err.stack : {},
	}

	if (res.getHeader("Content-Type") === "text/event-stream") {
		// Format the error according to SSE protocol if this is an SSE connection
		res.write(`data: ${JSON.stringify(errorInfo)}\n\n`)
	} else {
		res.write(JSON.stringify(errorInfo))
	}

	// Make sure the response hasn't been sent already
	if (res.headersSent) {
		return next(err)
	} else {
		res.status(errStatus)
		res.end()
	}
}

export default errorHandler
