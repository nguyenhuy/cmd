import OpenAI from "openai"
import { Stream } from "openai/streaming"
import { Completions } from "../completion"
import { Client, ClientBuilder } from "../client"
import { ChatModel } from "openai/resources/chat/chat"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"

export class OpenAIClient implements Client {
	private openai: OpenAI
	supportedModels: ChatModel[] = ["gpt-4o-mini", "o1", "o1-preview", "gpt-4o"]
	constructor({ apiKey }: { apiKey: string }) {
		this.openai = new OpenAI({
			apiKey,
		})
	}

	async chatCompletion(
		params: Completions.ChatCompletionCreateParamsStreaming,
	): Promise<AsyncIterable<Completions.ChatCompletionChunk>> {
		const streamingParams: OpenAI.Chat.Completions.ChatCompletionCreateParamsStreaming = {
			...params,
			stream: true,
		}

		const stream = await this.openai.chat.completions.create(streamingParams)
		return this._chatCompletion(stream)
	}

	async *_chatCompletion(
		stream: Stream<OpenAI.Chat.Completions.ChatCompletionChunk>,
	): AsyncIterable<Completions.ChatCompletionChunk> {
		for await (const chunk of stream) {
			yield chunk
		}
	}
}

export class OpenAIClientBuilder implements ClientBuilder {
	name: APIProviderName = "openai"
	build(params: { baseUrl?: string; apiKey?: string }): Client {
		return new OpenAIClient({
			apiKey: params.apiKey,
		})
	}
}
