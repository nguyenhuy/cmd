import { ModelProvider, ModelProviderOutput } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { createAnthropic } from "@ai-sdk/anthropic"
import { CoreMessage } from "ai"

export class AnthropicModelProvider implements ModelProvider {
	name: APIProviderName = "anthropic"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): ModelProviderOutput {
		const provider = createAnthropic({
			apiKey: params.apiKey,
			baseURL: process.env["ANTHROPIC_LOCAL_SERVER_PROXY"] ?? params.baseUrl,
		})
		return {
			model: provider(modelName),
			// generalProviderOptions: {
			// 	anthropic: {
			// 		thinking: { type: "enabled", budgetTokens: 12000 },
			// 	} satisfies AnthropicProviderOptions,
			// },
			addProviderOptionsToMessages: addCacheControlToMessages,
		}
	}
}

// Anthropic supports ephemeral caching for 4 messages.
// We cache the last content from 'system, the last and penultimate content from 'user'.
export const addCacheControlToMessages = (messages: Array<CoreMessage>): Array<CoreMessage> => {
	let systemContentToCache = 1
	let userContentToCache = 2

	for (let i = messages.length - 1; i >= 0; i--) {
		const message = messages[i]
		if (message.role === "system" && systemContentToCache > 0) {
			message.providerOptions = {
				anthropic: { cacheControl: { type: "ephemeral" } },
			}
			systemContentToCache--
		} else if (message.role === "user" && userContentToCache > 0) {
			if (typeof message.content === "string") {
				throw new Error("Unexpected string content in user message. Should use array of structured content.")
			} else {
				for (let j = message.content.length - 1; j >= 0; j--) {
					const content = message.content[j]
					if (userContentToCache > 0) {
						content.providerOptions = {
							anthropic: { cacheControl: { type: "ephemeral" } },
						}
						userContentToCache--
					}
				}
			}
		}
	}
	return messages
}
