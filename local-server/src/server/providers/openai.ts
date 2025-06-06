import { ModelProvider, ModelProviderInput, ModelProviderOutput } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { createOpenAI, OpenAIResponsesProviderOptions } from "@ai-sdk/openai"

export class OpenAIModelProvider implements ModelProvider {
	name: APIProviderName = "openai"
	build(params: ModelProviderInput): ModelProviderOutput {
		const { modelName, apiKey, baseUrl, reasoningBudget } = params
		const provider = createOpenAI({
			apiKey: apiKey,
			baseURL: process.env["OPENAI_LOCAL_SERVER_PROXY"] ?? baseUrl,
		})
		const providerOptions: OpenAIResponsesProviderOptions = {
			parallelToolCalls: true,
		}

		if (reasoningBudget) {
			providerOptions.reasoningEffort = "medium" // low, medium, and high
		}
		return {
			model: provider(modelName),

			generalProviderOptions: {
				openai: providerOptions,
			},
		}
	}
}
