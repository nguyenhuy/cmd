import { ModelProvider, ModelProviderOutput } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { createOpenAI } from "@ai-sdk/openai"

export class OpenAIModelProvider implements ModelProvider {
	name: APIProviderName = "openai"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): ModelProviderOutput {
		if (!["gpt-4o-mini", "o1", "o1-preview", "gpt-4o"].includes(modelName)) {
			return {}
		}

		const provider = createOpenAI({
			apiKey: params.apiKey,
			baseURL: process.env["OPENAI_LOCAL_SERVER_PROXY"] ?? params.baseUrl,
		})
		return {
			model: provider(modelName),
		}
	}
}
