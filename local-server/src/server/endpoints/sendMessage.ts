import { Request, Response, Router } from "express"
import { logError, logInfo } from "../../logger"
import { defaultSystemPrompt } from "../ai-context/system-prompts"
import { ClientBuilder } from "../lite-llm/client"
import {
	ChatCompletionChunk,
	ChatCompletionContentPart,
	ChatCompletionMessageParam,
	ChatCompletionTool,
	ChatCompletionAssistantMessageParam,
	ChatCompletionChunkError,
} from "../lite-llm/completion"
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
import { createAnthropic } from "@ai-sdk/anthropic"
import loadSecrets from "@/secrets"

export const registerEndpoint = (router: Router, clients: ClientBuilder[]) => {
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

			logInfo(
				JSON.stringify(
					{ baseURL: process.env["LOCAL_SERVER_PROXY"] ?? "https://api.anthropic.com/v1" },
					null,
					2,
				),
			)

			const provider = createAnthropic({
				apiKey: loadSecrets().ANTHROPIC_API_KEY,
				baseURL: process.env["LOCAL_SERVER_PROXY"] ?? "https://api.anthropic.com/v1",
			})
			const { fullStream } = await streamText({
				model: provider("claude-4-sonnet-20250514"),
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

			// const transformedMessages: ChatCompletionMessageParam[] = []
			// let currentUserMessageContent: ChatCompletionContentPart[] | undefined
			// const completeUserMessageIfNeeded = () => {
			// 	if (currentUserMessageContent) {
			// 		transformedMessages.push({
			// 			role: "user",
			// 			content: currentUserMessageContent,
			// 		})
			// 		currentUserMessageContent = undefined
			// 	}
			// }
			// for (const message of messages) {
			// 	if (message.role === "user") {
			// 		for (const content of message.content) {
			// 			if (content.type === "tool_result") {
			// 				// tool_results needs to be sent as a separate message, where the role is "tool", not "user".
			// 				completeUserMessageIfNeeded()
			// 				const toolResult =
			// 					content.result.type === "tool_result_success"
			// 						? content.result.success
			// 						: content.result.failure
			// 				transformedMessages.push({
			// 					role: "tool",
			// 					content: [
			// 						{
			// 							text: JSON.stringify(toolResult),
			// 							type: "text",
			// 						},
			// 					],
			// 					tool_call_id: content.tool_use_id,
			// 					is_error: content.result.type === "tool_result_failure",
			// 				})
			// 			} else if (content.type === "text") {
			// 				if (!currentUserMessageContent) {
			// 					currentUserMessageContent = []
			// 				}
			// 				currentUserMessageContent.push({
			// 					type: "text",
			// 					text: content.text,
			// 				})
			// 				if ((content.attachments?.length || 0) > 0) {
			// 					currentUserMessageContent.push({
			// 						type: "text",
			// 						text: "You can use this context provided by the user:",
			// 					})

			// 					content.attachments?.forEach((attachment) => {
			// 						if (attachment.type === "image_attachment") {
			// 							currentUserMessageContent.push({
			// 								type: "image_url",
			// 								image_url: {
			// 									url: attachment.url,
			// 								},
			// 							})
			// 						} else if (attachment.type === "file_attachment") {
			// 							currentUserMessageContent.push({
			// 								type: "text",
			// 								text: `\`\`\`${attachment.path}
			//           ${attachment.content}
			//           \`\`\`
			//           `,
			// 							})
			// 						} else if (attachment.type === "file_selection_attachment") {
			// 							currentUserMessageContent.push({
			// 								type: "text",
			// 								text: `\`\`\`${attachment.path} Line ${attachment.startLine} - ${attachment.endLine}
			//           ${attachment.content}
			//           \`\`\`
			//           `,
			// 							})
			// 						} else if (attachment.type === "build_error_attachment") {
			// 							currentUserMessageContent.push({
			// 								type: "text",
			// 								text: `Build Error ${attachment.filePath}:${attachment.line}:${attachment.column}: ${attachment.message}`,
			// 							})
			// 						}
			// 					})

			// 					currentUserMessageContent.push({
			// 						type: "text",
			// 						text: "End of context provided by the user.",
			// 					})
			// 				}
			// 			}
			// 		}
			// 	} else if (message.role === "assistant") {
			// 		completeUserMessageIfNeeded()

			// 		const newMessage: ChatCompletionAssistantMessageParam = {
			// 			role: "assistant",
			// 			content: message.content.filter((part) => part.type === "text"),
			// 			tool_calls: message.content
			// 				.filter((part) => part.type === "tool_call")
			// 				.map((part) => ({
			// 					id: part.id,
			// 					type: "function",
			// 					function: {
			// 						name: part.name,
			// 						arguments: JSON.stringify(part.input),
			// 					},
			// 				})),
			// 		}

			// 		transformedMessages.push(newMessage)
			// 	}
			// }
			// completeUserMessageIfNeeded()

			// logInfo(JSON.stringify({ transformedMessages }))

			// const transformedTools = tools?.map(
			// 	(tool): ChatCompletionTool => ({
			// 		type: "function",
			// 		function: {
			// 			name: tool.name,
			// 			description: tool.description,
			// 			parameters: tool.input_schema,
			// 		},
			// 	}),
			// )
			// logInfo(JSON.stringify({ transformedTools }))

			// const model = body.model
			// const clientBuilder = clients.find((client) => client.name === body.provider.name)
			// if (!clientBuilder) {
			// 	throw new UserFacingError({
			// 		message: `Unsupported API provider ${body.provider}.`,
			// 	})
			// }
			// const client = await clientBuilder.build(body.provider.settings)
			// if (!client.supportedModels.includes(model)) {
			// 	throw new UserFacingError({
			// 		message: `${model} is not supported by ${body.provider}.`,
			// 	})
			// }

			// const stream = await client.chatCompletion({
			// 	messages: [
			// 		{
			// 			role: "system",
			// 			content: (system || defaultSystemPrompt).replace(
			// 				/DIRECTORY_ROOT/g,
			// 				body.projectRoot || "<no project specificed>",
			// 			),
			// 		},
			// 		...transformedMessages,
			// 	],
			// 	stream: true,
			// 	model,
			// 	tools: transformedTools,
			// })

			// await processResponseStream(stream, res)
		} catch (error) {
			logInfo("Request body that led to error:\n\n" + JSON.stringify(req.body, null, 2))
			logError(error)

			throw addUserFacingError(error, "Failed to process message.")
		}
	})
}

// const isChatCompletionChunkError = (
// 	chunk: ChatCompletionChunk | ChatCompletionChunkError,
// ): chunk is ChatCompletionChunkError => {
// 	return "type" in chunk && chunk.type === "error"
// }

// async function processResponseStream(
// 	stream: AsyncIterable<ChatCompletionChunk | ChatCompletionChunkError>,
// 	res: Response,
// ) {
// 	try {
// 		const chunks: Array<StreamedResponseChunk> = []
// 		for await (const chunk of stream) {
// 			const transformChunk = (
// 				chunk: ChatCompletionChunk | ChatCompletionChunkError,
// 			): Array<StreamedResponseChunk> => {
// 				if (isChatCompletionChunkError(chunk)) {
// 					throw new UserFacingError({
// 						message: chunk.message,
// 						statusCode: chunk.statusCode,
// 					})
// 				}

// 				logInfo(`Sending chunk to host app: ${JSON.stringify(chunk)}`)
// 				const choice = chunk.choices[0]
// 				if (choice === undefined) {
// 					return []
// 				}

// 				const results: Array<StreamedResponseChunk> = []

// 				if (choice.delta.content) {
// 					results.push({
// 						type: "text_delta",
// 						text: choice.delta.content,
// 					})
// 				}

// 				choice.delta.tool_calls?.forEach((toolCall) => {
// 					const parsedInput =
// 						toolCall.function.arguments.length === 0
// 							? ({} as Record<string, unknown>)
// 							: (JSON.parse(toolCall.function.arguments) as Record<string, unknown>)

// 					results.push({
// 						type: "tool_call",
// 						name: toolCall.function.name,
// 						id: toolCall.id,
// 						input: parsedInput,
// 					})
// 				})

// 				return results
// 			}
// 			const newChunks = transformChunk(chunk)
// 			chunks.push(...newChunks)
// 			newChunks.forEach((chunk) => {
// 				if (res.getHeader("Content-Type") === undefined) {
// 					res.setHeader("Content-Type", "text/event-stream")
// 					res.setHeader("Cache-Control", "no-cache")
// 					res.setHeader("Connection", "keep-alive")
// 				}
// 				res.write(JSON.stringify(chunk))
// 			})
// 		}
// 		res.end()

// 		if (process.env.NODE_ENV === "development") {
// 			debugLogReceivedMessage(chunks)
// 		}
// 	} catch (error) {
// 		throw addUserFacingError(error, "Failed to send message.")
// 	}
// }

async function processResponseStream(stream: AsyncIterable<TextStreamPart<Record<string, MappedTool>>>, res: Response) {
	try {
		const chunks: Array<StreamedResponseChunk> = []
		for await (const chunk of stream) {
			const transformChunk = (
				chunk: TextStreamPart<Record<string, MappedTool>>,
			): Array<StreamedResponseChunk> => {
				// if (isChatCompletionChunkError(chunk)) {
				// 	throw new UserFacingError({
				// 		message: chunk.message,
				// 		statusCode: chunk.statusCode,
				// 	})
				// }

				logInfo(`processing received chunk: ${JSON.stringify(chunk)}`)
				// const choice = chunk.choices[0]
				// if (choice === undefined) {
				// 	return []
				// }

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
						logInfo(`Received tool call: ${JSON.stringify(chunk)}`)
						break
					case "error":
						throw new UserFacingError({
							message: chunk.error as string,
							statusCode: 500,
						})
					default:
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
		parameters: jsonSchema(tool.input_schema),
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
		const result: (CoreUserMessage | CoreToolMessage)[] = []
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
			} else if (content.type === "tool_result") {
				result.push({
					role: "tool",
					content: [
						{
							type: "tool-result",
							toolCallId: content.tool_use_id,
							toolName: content.tool_name,
							result: content.result,
						},
					],
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
	} else {
		throw new Error(`Unsupported message role: ${message.role}`)
	}
}
