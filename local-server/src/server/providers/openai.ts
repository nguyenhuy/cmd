import { ModelProvider, ModelProviderInput, ModelProviderOutput } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { createOpenAI } from "@ai-sdk/openai"

export class OpenAIModelProvider implements ModelProvider {
	name: APIProviderName = "openai"
	build(params: ModelProviderInput): ModelProviderOutput {
		const { modelName, apiKey, baseUrl } = params
		const provider = createOpenAI({
			apiKey: apiKey,
			baseURL: process.env["OPENAI_LOCAL_SERVER_PROXY"] ?? baseUrl,
		})
		return {
			model: provider(modelName),
		}
	}
}
