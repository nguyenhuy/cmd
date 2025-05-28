import { Request, Response, Router } from "express"
import { logError, logInfo } from "../../logger"
import { ModelProvider } from "../providers/provider"
import {
	Message,
	MessageContent,
	SendMessageRequestParams,
	StreamedResponseChunk,
	TextMessage,
	Tool,
	ToolResultMessage,
	ToolUseRequest,
} from "../schemas/sendMessageSchema"
import { addUserFacingError, UserFacingError } from "../errors"

import {
	CoreAssistantMessage,
	CoreMessage,
	CoreToolMessage,
	CoreUserMessage,
	streamText,
	Tool as MappedTool,
	jsonSchema,
	TextStreamPart,
	TextPart,
	ImagePart,
	FilePart,
	CoreSystemMessage,
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
			const system = body.system
			messages = [
				{
					role: "system",
					content: [
						{
							type: "text",
							text: system,
						},
					],
				} as Message,
				...messages.filter((message) => message.content.length > 0),
			]

			const tools = body.tools

			const modelProvider = modelProviders.find((provider) => provider.name === body.provider.name)
			if (!modelProvider) {
				throw new UserFacingError({
					message: `Unsupported API provider ${body.provider.name}.`,
				})
			}
			const modelName = body.model
			const { model, generalProviderOptions, addProviderOptionsToMessages } = await modelProvider.build(
				body.provider.settings,
				modelName,
			)
			if (!model) {
				throw new UserFacingError({
					message: `Unsupported model: ${modelName} is not supported by ${body.provider.name}.`,
				})
			}
			const { fullStream } = await streamText({
				model,
				tools: tools?.map(mapTool).reduce(
					(acc, tool) => {
						acc[tool.name] = tool
						return acc
					},
					{} as Record<string, MappedTool>,
				),
				messages: addProviderOptionsToMessages(messages.map(mapMessage)),
				toolCallStreaming: true,
				providerOptions: generalProviderOptions,
			})

			processResponseStream(fullStream, res)
		} catch (error) {
			logInfo("Request body that led to error:\n\n" + JSON.stringify(req.body, null, 2))
			logError(error)

			throw addUserFacingError(error, "Failed to process message.")
		}
	})
}

/**
 * Processes the response stream received from the provider (and already parsed by Vercel's AI SDK) and convert it to the format expected by the app.
 * @param stream - The resonse stream.
 * @param res - The Express response object to write the streamed response chunks to.
 * @throws {UserFacingError} If an error occurs while processing the stream or sending the response.
 */
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

/**
 * Maps a Tool to the format expected by the AI SDK.
 */
const mapTool = (tool: Tool): MappedTool & { name: string } => {
	return {
		description: tool.description,
		name: tool.name,
		parameters: jsonSchema(tool.inputSchema),
	}
}

/**
 * Maps a Message to the format expected by the AI SDK.
 */
const mapMessage = (message: Message): CoreMessage => {
	if (message.role === "system") {
		if (message.content.map(asTextMessage).length !== 1) {
			throw new Error(`System message must have exactly one text content part. Got ${message.content.length}`)
		}
		return {
			role: "system",
			content: message.content.map(asTextMessage)[0].text,
		} as CoreSystemMessage
	} else if (message.role === "user") {
		return {
			role: "user",
			content: message.content.map(asTextMessage).flatMap((content) => {
				const result: Array<TextPart | ImagePart | FilePart> = []
				result.push({
					type: "text",
					text: content.text,
				})
				content.attachments?.forEach((attachment) => {
					switch (attachment.type) {
						case "image_attachment":
							result.push({
								type: "image",
								image: attachment.url,
								mimeType: attachment.mimeType,
							})
							break
						case "file_attachment":
							result.push({
								type: "text",
								text: `\`\`\`${attachment.path}
							${attachment.content}
							\`\`\`
							`,
							})
							break
						case "file_selection_attachment":
							result.push({
								type: "text",
								text: `\`\`\`${attachment.path} Line ${attachment.startLine} - ${attachment.endLine}
                      ${attachment.content}
                      \`\`\`
                      `,
							})
							break
						case "build_error_attachment":
							result.push({
								type: "text",
								text: `Build Error ${attachment.filePath}:${attachment.line}:${attachment.column}: ${attachment.message}`,
							})
							break
					}
				})
				return result
			}),
		} as CoreUserMessage
	} else if (message.role === "assistant") {
		return {
			role: "assistant",
			content: message.content.map((content) => {
				if (isTextMessage(content)) {
					return {
						type: "text",
						text: content.text,
					} as TextPart
				}
				if (isToolUseRequestMessage(content)) {
					return {
						type: "tool-call",
						toolCallId: content.toolUseId,
						toolName: content.toolName,
						args: content.input,
					}
				}
				throw new Error(`Unsupported content type: ${content.type}`)
			}),
		} as CoreAssistantMessage
	} else if (message.role === "tool") {
		return {
			role: "tool",
			content: message.content.map(asToolResultMessage).map((content) => ({
				type: "tool-result",
				toolCallId: content.toolUseId,
				toolName: content.toolName,
				result: content.result,
			})),
		} as CoreToolMessage
	} else {
		throw new Error(`Unsupported message role: ${message.role}`)
	}
}

export const isTextMessage = (message: MessageContent): message is TextMessage => {
	return message.type === "text"
}

export const asTextMessage = (message: MessageContent): TextMessage => {
	if (!isTextMessage(message)) {
		throw new Error(`Unexpected message type ${message.type}, expected 'text'`)
	}
	return message
}

export const isToolResultMessage = (message: MessageContent): message is ToolResultMessage => {
	return message.type === "tool_result"
}

export const asToolResultMessage = (message: MessageContent): ToolResultMessage => {
	if (!isToolResultMessage(message)) {
		throw new Error(`Unexpected message type ${message.type}, expected 'tool_result'`)
	}
	return message
}
export const isToolUseRequestMessage = (message: MessageContent): message is ToolUseRequest => {
	return message.type === "tool_call"
}

export const asToolUseRequestMessage = (message: MessageContent): ToolUseRequest => {
	if (!isToolUseRequestMessage(message)) {
		throw new Error(`Unexpected message type ${message.type}, expected 'tool_call'`)
	}
	return message
}
