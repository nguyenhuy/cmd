import { CoreMessage, JSONValue, LanguageModel } from "ai"
import { APIProviderName } from "../schemas/sendMessageSchema"

export type ModelProviderOutput = {
	model?: LanguageModel
	generalProviderOptions?: Record<string, Record<string, JSONValue>>
	addProviderOptionsToMessages?: (messages: Array<CoreMessage>) => Array<CoreMessage>
}

export type ModelProviderInput = {
	baseUrl?: string
	apiKey?: string
	modelName: string
	reasoningBudget?: number
}
export interface ModelProvider {
	build: (params: ModelProviderInput) => ModelProviderOutput
	name: APIProviderName
}
