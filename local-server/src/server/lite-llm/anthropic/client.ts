import { Completions } from "../completion"
import { Client, ClientBuilder } from "../client"
import { Anthropic } from "@anthropic-ai/sdk"
import {
	formattedMessage,
	formattedSystemMessage,
	formattedTool,
	StreamedChatCompletionResponseConverter,
} from "./converters"
import { logInfo } from "../../../logger"
import { UserFacingError } from "../../errors"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"

export class AnthropicClient implements Client {
	supportedModels: string[] = ["claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest"]
	private apiKey: string
	private baseUrl: string

	constructor({ apiKey, baseUrl }: { apiKey: string; baseUrl?: string }) {
		this.apiKey = apiKey
		this.baseUrl = process.env["LOCAL_SERVER_PROXY"] ?? baseUrl ?? "https://api.anthropic.com/v1"
	}

	async chatCompletion(
		params: Completions.ChatCompletionCreateParamsStreaming,
	): Promise<AsyncIterable<Completions.ChatCompletionChunk | Completions.ChatCompletionChunkError>> {
		const body: Anthropic.Messages.MessageCreateParamsStreaming = {
			model: params.model,
			max_tokens: 4096,
			messages: params.messages
				.filter((message) => message.role !== "system" && message.role !== "developer")
				.map(formattedMessage),
			system: params.messages
				.filter((message) => message.role === "system" || message.role === "developer")
				.flatMap(formattedSystemMessage),
			tools: params.tools?.map(formattedTool),
			stream: true,
		}

		const response = await fetch(`${this.baseUrl}/messages`, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				"x-api-key": this.apiKey,
				"anthropic-version": "2023-06-01",
			},
			body: JSON.stringify(body),
		})

		if (!response.ok) {
			const errorText = await response.text()
			throw new UserFacingError({
				message: `Anthropic API error: ${errorText}`,
				statusCode: response.status,
				underlyingError: new Error(errorText),
			})
		}

		if (!response.body) {
			throw new UserFacingError({
				message: "Anthropic API error: No response body received",
			})
		}

		logInfo(`Anthropic API response: ${response.status} ${JSON.stringify(response.body)}`)
		return this._sendMessage(response)
	}

	async *_sendMessage(
		response: Response,
	): AsyncIterable<Completions.ChatCompletionChunk | Completions.ChatCompletionChunkError> {
		const reader = response.body.getReader()
		const decoder = new TextDecoder()
		let buffer = ""
		const converter = new StreamedChatCompletionResponseConverter()

		try {
			while (true) {
				const { done, value } = await reader.read()
				if (done) break

				buffer += decoder.decode(value, { stream: true })
				const lines = buffer.split("\n")
				buffer = lines.pop() || ""

				for (const line of lines) {
					const dataHeader = "data: "
					if (line.startsWith(dataHeader)) {
						const data = line.slice(dataHeader.length)
						if (data === "[DONE]") continue

						const event = JSON.parse(data) as
							| Anthropic.Messages.RawMessageStreamEvent
							| { type: "error"; error: { type: string; message: string } }
						if (event.type === "error") {
							// We received an error event from Anthropic.
							yield {
								type: "error",
								message: `Anthropic API error: ${event.error.message}`,
								statusCode: 500,
							}
							return
						}

						const chunks = converter.convert(event)

						for (const chunk of chunks) {
							yield chunk
						}
					}
				}
			}
		} catch (error) {
			yield {
				type: "error",
				message: `Anthropic API error: ${error}`,
				statusCode: 500,
			}
		} finally {
			reader.releaseLock()
		}
	}
}

export class AnthropicClientBuilder implements ClientBuilder {
	name: APIProviderName = "anthropic"
	build(params: { baseUrl?: string; apiKey?: string }): Client {
		return new AnthropicClient({
			apiKey: params.apiKey,
			baseUrl: params.baseUrl,
		})
	}
}
