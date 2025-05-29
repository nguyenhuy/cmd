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
			addProviderOptionsToMessages: (messages) => addCacheControlToMessages(messages, this.name),
		}
	}
}

// Anthropic supports ephemeral caching for 4 messages.
// We cache the last content from 'system, the last and penultimate content from 'user'.
export const addCacheControlToMessages = (messages: Array<CoreMessage>, providerName: string): Array<CoreMessage> => {
	// Create a deep copy of messages for the objects of interest to avoid mutating the original value.
	const newMessages = [...messages]
	let systemContentToCache = 1
	let userContentToCache = 2

	for (let i = newMessages.length - 1; i >= 0; i--) {
		const message = newMessages[i]
		if (message.role === "system" && systemContentToCache > 0) {
			newMessages[i] = {
				...message,
				providerOptions: {
					[providerName]: { cacheControl: { type: "ephemeral" } },
				},
			}
			systemContentToCache -= 1
		} else if (message.role === "user" && userContentToCache > 0) {
			if (typeof message.content === "string") {
				throw new Error("Unexpected string content in user message. Should use array of structured content.")
			} else {
				for (let j = message.content.length - 1; j >= 0; j--) {
					if (userContentToCache > 0) {
						const newMessage = {
							...message,
							content: [...message.content],
						}
						newMessage.content[j] = {
							...newMessage.content[j],
							providerOptions: {
								[providerName]: { cacheControl: { type: "ephemeral" } },
							},
						}
						newMessages[i] = newMessage
						userContentToCache -= 1
					}
				}
			}
		}
	}
	return newMessages
}
