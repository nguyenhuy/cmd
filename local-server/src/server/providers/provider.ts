import { CoreMessage, JSONValue, LanguageModel } from "ai"
import { APIProviderName } from "../schemas/sendMessageSchema"

export type ModelProviderOutput = {
	model?: LanguageModel
	generalProviderOptions?: Record<string, Record<string, JSONValue>>
	addProviderOptionsToMessages?: (messages: Array<CoreMessage>) => Array<CoreMessage>
}
export interface ModelProvider {
	build: (params: { baseUrl?: string; apiKey?: string }, modelName: string) => ModelProviderOutput
	name: APIProviderName
}
