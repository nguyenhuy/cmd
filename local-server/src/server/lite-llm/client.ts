import { APIProviderName } from "../schemas/sendMessageSchema"
import { ChatCompletionCreateParamsStreaming, ChatCompletionChunk, ChatCompletionChunkError } from "./completion"

export interface ClientBuilder {
	build: (params: { baseUrl?: string; apiKey?: string }) => Client
	name: APIProviderName
}

export interface Client {
	chatCompletion: ChatCompletionStreamedRPC
	supportedModels: string[]
}

export type RPC<Request, Response> = (request: Request) => Promise<Response>

export type StreamedRPC<Request, Response> = RPC<Request, AsyncIterable<Response>>

export type ChatCompletionStreamedRPC = StreamedRPC<
	ChatCompletionCreateParamsStreaming,
	ChatCompletionChunk | ChatCompletionChunkError
>
