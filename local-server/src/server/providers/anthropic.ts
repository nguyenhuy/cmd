import { ModelProvider } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { LanguageModel } from "ai"
import { createAnthropic } from "@ai-sdk/anthropic"

export class AnthropicModelProvider implements ModelProvider {
	name: APIProviderName = "anthropic"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): LanguageModel {
		if (!["claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219"].includes(modelName)) {
			return undefined
		}

		const provider = createAnthropic({
			apiKey: params.apiKey,
			baseURL: process.env["LOCAL_SERVER_PROXY"] ?? params.baseUrl ?? "https://api.anthropic.com/v1",
		})
		return provider(modelName)
	}
}
