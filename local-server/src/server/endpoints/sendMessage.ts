import { Request, Response, Router } from "express"
import { logError, logInfo } from "../../logger"
import { ModelProvider } from "../providers/provider"
import { Message, SendMessageRequestParams, StreamedResponseChunk, Tool } from "../schemas/sendMessageSchema"
import { addUserFacingError, UserFacingError } from "../errors"

import {
	CoreAssistantMessage,
	CoreMessage,
	CoreSystemMessage,
	CoreToolMessage,
	CoreUserMessage,
	streamText,
	Tool as MappedTool,
	jsonSchema,
	TextStreamPart,
} from "ai"

export const registerEndpoint = (router: Router, modelProviders: ModelProvider[]) => {
	router.post("/sendMessage", async (req: Request, res: Response) => {
		if (!req.body) {
			throw new UserFacingError({
				message: "Missing body",
				statusCode: 400,
			})
		}

		try {
			const body = req.body as SendMessageRequestParams
			let messages = body.messages
			messages = messages.filter((message) => message.content.length > 0)
			const system = body.system
			const tools = body.tools

			const modelProvider = modelProviders.find((provider) => provider.name === body.provider.name)
			if (!modelProvider) {
				throw new UserFacingError({
					message: `Unsupported API provider ${body.provider.name}.`,
				})
			}
			const modelName = body.model
			const model = await modelProvider.build(body.provider.settings, modelName)
			if (!model) {
				throw new UserFacingError({
					message: `Unsupported model: ${modelName} is not supported by ${body.provider.name}.`,
				})
			}
			const { fullStream } = await streamText({
				model,
				system,
				tools: tools?.map(mapTool).reduce(
					(acc, tool) => {
						acc[tool.name] = tool
						return acc
					},
					{} as Record<string, MappedTool>,
				),
				messages: messages.flatMap(mapMessage),
				toolCallStreaming: true,
			})

			processResponseStream(fullStream, res)
		} catch (error) {
			logInfo("Request body that led to error:\n\n" + JSON.stringify(req.body, null, 2))
			logError(error)

			throw addUserFacingError(error, "Failed to process message.")
		}
	})
}

async function processResponseStream(stream: AsyncIterable<TextStreamPart<Record<string, MappedTool>>>, res: Response) {
	try {
		const chunks: Array<StreamedResponseChunk> = []
		for await (const chunk of stream) {
			const transformChunk = (
				chunk: TextStreamPart<Record<string, MappedTool>>,
			): Array<StreamedResponseChunk> => {
				const results: Array<StreamedResponseChunk> = []
				switch (chunk.type) {
					case "text-delta":
						results.push({
							type: "text_delta",
							text: chunk.textDelta,
						})
						break
					case "tool-call-delta":
						results.push({
							type: "tool_call_delta",
							toolName: chunk.toolName,
							toolUseId: chunk.toolCallId,
							inputDelta: chunk.argsTextDelta,
						})
						break
					case "tool-call":
						results.push({
							type: "tool_call",
							toolName: chunk.toolName,
							toolUseId: chunk.toolCallId,
							input: chunk.args,
						})
						break
					case "error":
						throw new UserFacingError({
							message: chunk.error as string,
							statusCode: 500,
						})
					default:
						logInfo(`skipping chunk: ${chunk.type}`)
						break
				}

				return results
			}
			const newChunks = transformChunk(chunk)
			chunks.push(...newChunks)
			newChunks.forEach((chunk) => {
				if (res.getHeader("Content-Type") === undefined) {
					res.setHeader("Content-Type", "text/event-stream")
					res.setHeader("Cache-Control", "no-cache")
					res.setHeader("Connection", "keep-alive")
				}
				res.write(JSON.stringify(chunk))
			})
		}
		res.end()

		if (process.env.NODE_ENV === "development") {
			debugLogReceivedMessage(chunks)
		}
	} catch (error) {
		throw addUserFacingError(error, "Failed to send message.")
	}
}

const debugLogReceivedMessage = (chunks: Array<StreamedResponseChunk>) => {
	let messageType: "error" | "text_delta" | "tool_call" | "tool_call_delta" | undefined
	let text: string | undefined

	const logLastObject = () => {
		if (text !== undefined) {
			logInfo(`Received text:\n${text}`)
			text = undefined
		}
	}
	for (const chunk of chunks) {
		if (chunk.type !== messageType) {
			logLastObject()
		}
		messageType = chunk.type
		if (chunk.type === "text_delta") {
			text = text ?? ""
			text += chunk.text
		} else if (chunk.type === "tool_call") {
			logInfo(`Received tool call:\n${JSON.stringify(chunk)}`)
		} else if (chunk.type === "error") {
			logInfo(`Received error:\n${JSON.stringify(chunk)}`)
		}
	}
	logLastObject()
}

const mapTool = (tool: Tool): MappedTool & { name: string } => {
	return {
		description: tool.description,
		name: tool.name,
		parameters: jsonSchema(tool.inputSchema),
	}
}

const mapMessage = (message: Message): CoreMessage[] => {
	if (message.role === "system") {
		const result: CoreSystemMessage[] = []
		message.content.forEach((content) => {
			if (content.type === "text") {
				result.push({
					role: "system",
					content: content.text,
				})
			} else {
				throw new Error(`Unsupported system message content type: ${content.type}`)
			}
		})
		return result
	} else if (message.role === "user") {
		const result: CoreUserMessage[] = []
		message.content.forEach((content) => {
			// TODO: use "tool" as the role for tool results, and don't split into one message each content part.
			if (content.type === "text") {
				result.push({
					role: "user",
					content: content.text,
				})
				content.attachments?.forEach((attachment) => {
					switch (attachment.type) {
						case "image_attachment":
							result.push({
								role: "user",
								content: [
									{
										type: "image",
										image: attachment.url,
										mimeType: attachment.mimeType,
									},
								],
							})
							break
						case "file_attachment":
							result.push({
								role: "user",
								content: `\`\`\`${attachment.path}
							${attachment.content}
							\`\`\`
							`,
							})
							break
						case "file_selection_attachment":
							result.push({
								role: "user",
								content: `\`\`\`${attachment.path} Line ${attachment.startLine} - ${attachment.endLine}
                      ${attachment.content}
                      \`\`\`
                      `,
							})
							break
						case "build_error_attachment":
							result.push({
								role: "user",
								content: `Build Error ${attachment.filePath}:${attachment.line}:${attachment.column}: ${attachment.message}`,
							})
							break
					}
				})
			} else {
				throw new Error(`Unsupported content type: ${content.type}`)
			}
		})
		return result
	} else if (message.role === "assistant") {
		const result: CoreAssistantMessage[] = []
		message.content.forEach((content) => {
			if (content.type === "text") {
				result.push({
					role: "assistant",
					content: content.text,
				})
			} else if (content.type === "tool_call") {
				result.push({
					role: "assistant",
					content: [
						{
							type: "tool-call",
							toolCallId: content.toolUseId,
							toolName: content.toolName,
							args: content.input,
						},
					],
				})
			}
		})
		return result
	} else if (message.role === "tool") {
		const result: CoreToolMessage[] = []
		message.content.forEach((content) => {
			if (content.type === "tool_result") {
				result.push({
					role: "tool",
					content: [
						{
							type: "tool-result",
							toolCallId: content.toolUseId,
							toolName: content.toolName,
							result: content.result,
						},
					],
				})
			}
		})
		return result
	} else {
		throw new Error(`Unsupported message role: ${message.role}`)
	}
}
