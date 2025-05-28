import { ModelProvider } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { LanguageModel } from "ai"
import { createOpenAI } from "@ai-sdk/openai"

export class OpenAIModelProvider implements ModelProvider {
	name: APIProviderName = "openai"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): LanguageModel {
		if (!["gpt-4o-mini", "o1", "o1-preview", "gpt-4o"].includes(modelName)) {
			return undefined
		}

		const provider = createOpenAI({
			apiKey: params.apiKey,
			baseURL: process.env["OPENAI_LOCAL_SERVER_PROXY"] ?? params.baseUrl,
		})
		return provider(modelName)
	}
}
