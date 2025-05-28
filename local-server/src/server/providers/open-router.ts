import { ModelProvider, ModelProviderOutput } from "./provider"
import { APIProviderName } from "@/server/schemas/sendMessageSchema"
import { createOpenRouter, OpenRouterProviderOptions } from "@openrouter/ai-sdk-provider"
import { addCacheControlToMessages } from "./anthropic"

export class OpenRouterModelProvider implements ModelProvider {
	name: APIProviderName = "openrouter"
	build(params: { baseUrl?: string; apiKey?: string }, modelName: string): ModelProviderOutput {
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
			return {}
		}

		const provider = createOpenRouter({
			apiKey: params.apiKey,
			baseURL: process.env["OPEN_ROUTER_LOCAL_SERVER_PROXY"] ?? params.baseUrl,
			fetch: modelName.startsWith("anthropic/") ? fetchAnthropicResponse : defaultFetch,
		})
		return {
			model: provider(modelName),
			generalProviderOptions: {
				openRouter: {
					// reasoning: {
					// 	effort: "high",
					// },
				} satisfies OpenRouterProviderOptions,
			},
			addProviderOptionsToMessages: modelName.startsWith("anthropic/") ? addCacheControlToMessages : undefined,
		}
	}
}

const defaultFetch: typeof fetch = (input, init) => {
	if (!init?.body) return fetch(input, init)

	const body = JSON.parse(init.body as string)

	body.stream_options = {
		include_usage: true,
	}
	body.transforms = ["middle-out"]
	body.usage = { include: true }

	init.body = JSON.stringify(body)

	return fetch(input, init)
}

// See https://github.com/OpenRouterTeam/ai-sdk-provider/issues/35#issuecomment-2904161662
const fetchAnthropicResponse: typeof fetch = (input, init) => {
	if (!init?.body) return fetch(input, init)

	const body = JSON.parse(init.body as string)

	body.stream_options = {
		include_usage: true,
	}
	body.transforms = ["middle-out"]
	body.usage = { include: true }

	if (body?.messages) {
		for (const message of body.messages) {
			if (typeof message.content === "string") {
				message.content = [
					{
						type: "text",
						text: message.content,
						cache_control: { type: "ephemeral" },
					},
				]
			} else if (Array.isArray(message.content)) {
				for (const item of message.content) {
					if (item && typeof item === "object") {
						item.cache_control = { type: "ephemeral" }
					}
				}
			}
		}
	}
	init.body = JSON.stringify(body)

	return fetch(input, init)
}
