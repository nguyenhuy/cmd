import {
	ChatCompletionContentPart,
	ChatCompletionUserMessageParam,
	ChatCompletionAssistantMessageParam,
	ChatCompletionToolMessageParam,
	Completions,
	ChatCompletionSystemMessageParam,
	ChatCompletionDeveloperMessageParam,
	ChatCompletionTool,
} from "../completion"
import { Anthropic } from "@anthropic-ai/sdk"
import { ContentBlockParam, ToolUseBlockParam } from "@anthropic-ai/sdk/resources/messages"
import { logError } from "../../../logger"

export const formattedSystemMessage = (
	message: ChatCompletionDeveloperMessageParam | ChatCompletionSystemMessageParam,
): Anthropic.Messages.TextBlockParam[] => {
	if (typeof message.content === "string") {
		return [
			{
				type: "text",
				text: message.content,
			},
		]
	}
	return message.content.map((part) => ({
		type: "text",
		text: part.text,
	}))
}

const formatContent = (
	role: "user" | "assistant",
	content: string | ChatCompletionContentPart[],
): ContentBlockParam[] => {
	// TODO: tool use.
	if (typeof content === "string") {
		return [{ type: "text", text: content }]
	}
	return content.map((part) => {
		if (part.type === "text") {
			return { type: "text", text: part.text }
		} else if (part.type === "image_url") {
			// The url is encoded like this: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
			// The base64 data starts after the first comma.
			const extractBase64Data = (url: string): string => {
				const parts = url.split(",")
				return parts[parts.length - 1]
			}
			return {
				type: "image",
				source: {
					type: "base64",
					data: extractBase64Data(part.image_url.url), // TODO: handle different types: "image/jpeg" | "image/png" | "image/gif" | "image/webp"
					media_type: "image/png", // TODO: handle different types: "image/jpeg" | "image/png" | "image/gif" | "image/webp"
				},
			}
		}
		return undefined
	})
}

export const formattedMessage = (
	message: ChatCompletionUserMessageParam | ChatCompletionAssistantMessageParam | ChatCompletionToolMessageParam,
): Anthropic.Messages.MessageParam => {
	if (message.role === "tool") {
		const content: Anthropic.Messages.ToolResultBlockParam = {
			type: "tool_result",
			tool_use_id: message.tool_call_id,
			content: message.content,
			is_error: message.is_error,
		}
		return {
			role: "user",
			content: [content],
		}
	}
	if (message.role === "assistant") {
		const tool_uses: ToolUseBlockParam[] =
			message.tool_calls?.map((tool_call) => ({
				type: "tool_use",
				id: tool_call.id,
				name: tool_call.function.name,
				input: JSON.parse(tool_call.function.arguments),
			})) || []
		const content = formatContent(message.role, message.content)
		return {
			role: message.role,
			content: [...content, ...tool_uses],
		}
	}
	if (message.role === "user") {
		return {
			role: message.role,
			content: formatContent(message.role, message.content),
		}
	}
	// @ts-expect-error Unreachable.
	throw new Error(`Unknown message role ${message.role}`)
}

export const formattedTool = (tool: ChatCompletionTool): Anthropic.Messages.Tool => {
	return {
		name: tool.function.name,
		description: tool.function.description,
		input_schema: {
			type: "object",
			...tool.function.parameters,
		},
	}
}

export class StreamedChatCompletionResponseConverter {
	private message: Anthropic.Messages.Message | undefined
	private created: number | undefined
	private hasStartedStreamingContent = false

	private currentBlock: Anthropic.Messages.ContentBlock | undefined
	// Tool
	private partial_json: string | undefined
	private tool_use: Anthropic.ToolUseBlock | undefined

	constructor() {}

	convert(event: Anthropic.Messages.RawMessageStreamEvent): Completions.ChatCompletionChunk[] {
		const result: Completions.ChatCompletionChunk[] = []

		switch (event.type) {
			case "message_start":
				this.message = event.message
				this.created = Date.now()
				return []
			case "content_block_start":
				this.currentBlock = event.content_block
				if (this.currentBlock.type === "tool_use") {
					this.tool_use = this.currentBlock
					this.partial_json = ""
				}
				break
			case "content_block_delta":
				if (event.delta.type === "text_delta" && this.currentBlock?.type === "text") {
					if (!this.hasStartedStreamingContent) {
						result.push({
							id: this.message?.id,
							created: this.created,
							model: this.message?.model,
							object: "chat.completion.chunk",
							choices: [
								{
									index: 0,
									delta: { role: "assistant", content: "" },
									finish_reason: null,
								},
							],
						})
						this.hasStartedStreamingContent = true
					}
					result.push({
						id: this.message?.id,
						created: this.created,
						model: this.message?.model,
						object: "chat.completion.chunk",
						choices: [
							{
								index: 0,
								delta: { content: event.delta.text },
								finish_reason: null,
							},
						],
					})
				} else if (event.delta.type === "input_json_delta" && this.currentBlock?.type === "tool_use") {
					this.partial_json += event.delta.partial_json
				}
				break
			case "content_block_stop":
				if (this.currentBlock?.type === "text") {
					result.push({
						id: this.message?.id,
						created: this.created,
						model: this.message?.model,
						object: "chat.completion.chunk",
						choices: [
							{
								index: 0,
								delta: {},
								finish_reason: "stop",
							},
						],
					})
				}
				if (this.currentBlock?.type === "tool_use" && this.tool_use !== undefined) {
					let input: Record<string, unknown> = {}
					const tool_use = this.tool_use
					const partial_json = this.partial_json
					this.tool_use = undefined
					this.partial_json = undefined

					try {
						if (partial_json !== undefined && partial_json.length > 0) {
							input = JSON.parse(partial_json) as Record<string, unknown>
						}

						const mergedInput: Record<string, unknown> = {
							...((tool_use.input as Record<string, unknown> | undefined) || {}),
							...input,
						}

						result.push({
							id: this.message?.id,
							created: this.created,
							model: this.message?.model,
							object: "chat.completion.chunk",
							choices: [
								{
									index: 0,
									delta: {
										tool_calls: [
											{
												index: 0,
												type: "function",
												id: tool_use.id,
												function: {
													arguments: JSON.stringify(mergedInput),
													name: tool_use.name,
												},
											},
										],
									},
									finish_reason: "tool_calls",
								},
							],
						})
					} catch (e) {
						logError(e)
					}
				}
				break
		}
		return result
	}
}
