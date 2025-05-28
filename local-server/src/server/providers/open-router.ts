import { ModelProvider } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { LanguageModel } from "ai"
import { createOpenRouter } from "@openrouter/ai-sdk-provider"

export class OpenRouterModelProvider implements ModelProvider {
	name: APIProviderName = "openrouter"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): LanguageModel {
		if (
			![
				"anthropic/claude-3.7-sonnet",
				"anthropic/claude-sonnet-4",
				"anthropic/claude-opus-4",
				"anthropic/claude-3.5-haiku",
				"openai/gpt-4.1",
				"openai/gpt-4o",
				"openai/o4-mini",
			].includes(modelName)
		) {
			return undefined
		}

		const provider = createOpenRouter({
			apiKey: params.apiKey,
			baseURL: process.env["OPEN_ROUTER_LOCAL_SERVER_PROXY"] ?? params.baseUrl,
		})
		return provider(modelName)
	}
}
