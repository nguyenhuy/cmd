import { LanguageModel } from "ai"
import { APIProviderName } from "../schemas/sendMessageSchema"

export interface ModelProvider {
	build: (params: { baseUrl?: string; apiKey?: string }, modelName: string) => LanguageModel | undefined
	name: APIProviderName
}
