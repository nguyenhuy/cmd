import { describe, expect, it, jest, beforeEach } from "@jest/globals"
import { AnthropicClient } from "../client"
import { Completions } from "../../completion"

const TEST_DATE = "2025-02-22T00:00:00.000Z"
const TEST_DATE_MS = Date.parse("2025-02-22T00:00:00.000Z")

jest.useFakeTimers({
	doNotFake: [
		"setImmediate",
		"clearImmediate",
		"setTimeout",
		"clearTimeout",
		"setInterval",
		"clearInterval",
		"nextTick",
		"queueMicrotask",
	],
	now: new Date(TEST_DATE),
})

describe("AnthropicClient", () => {
	let mockFetch: jest.Mock<() => Promise<Response>>
	let client: AnthropicClient

	beforeEach(() => {
		mockFetch = jest.fn<() => Promise<Response>>()
		globalThis.fetch = mockFetch as unknown as typeof fetch

		client = new AnthropicClient({ apiKey: "test-key" })
	})

	it("correctly processes a tool use event stream", async () => {
		// Mock the ReadableStream
		const events = [
			'data: {"type":"message_start","message":{"id":"msg_017d9hsprnr9Zu6SQ1zsacKD","type":"message","role":"assistant","model":"claude-3-5-sonnet-20241022","content":[],"stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":1840,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":2}}}',
			'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}',
			'data: {"type":"ping"}',
			'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"I\'ll"}}',
			'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" check your current focused file using the get_focussed_"}}',
			'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"file function."}}',
			'data: {"type":"content_block_stop","index":0}',
			'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01X2agizghTNZJxARoV8r7aL","name":"get_focussed_file","input":{}}}',
			'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":""}}',
			'data: {"type":"content_block_stop","index":1}',
			'data: {"type":"message_delta","delta":{"stop_reason":"tool_use","stop_sequence":null},"usage":{"output_tokens":59}}',
			'data: {"type":"message_stop"}',
		].join("\n")

		const mockStream = new ReadableStream<Uint8Array<ArrayBufferLike>>({
			start(controller) {
				controller.enqueue(new TextEncoder().encode(events))
				controller.close()
			},
		})

		mockFetch.mockResolvedValue({
			ok: true,
			body: mockStream,
		} as Response)

		const request: Completions.ChatCompletionCreateParamsStreaming = {
			stream: true,
			model: "claude-3-5-sonnet-latest",
			messages: [{ role: "user", content: "test message" }],
			tools: [
				{
					type: "function",
					function: {
						name: "get_focussed_file",
						description: "Get the focused file",
						parameters: { type: "object", properties: {} },
					},
				},
			],
		}

		const expectedChunks: Completions.ChatCompletionChunk[] = [
			{
				choices: [
					{
						delta: {
							content: "",
							role: "assistant",
						},
						finish_reason: null,
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
			{
				choices: [
					{
						delta: {
							content: "I'll",
						},
						finish_reason: null,
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
			{
				choices: [
					{
						delta: {
							content: " check your current focused file using the get_focussed_",
						},
						finish_reason: null,
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
			{
				choices: [
					{
						delta: {
							content: "file function.",
						},
						finish_reason: null,
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
			{
				choices: [
					{
						delta: {},
						finish_reason: "stop",
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
			{
				choices: [
					{
						delta: {
							tool_calls: [
								{
									function: {
										arguments: "{}",
										name: "get_focussed_file",
									},
									id: "toolu_01X2agizghTNZJxARoV8r7aL",
									index: 0,
									type: "function",
								},
							],
						},
						finish_reason: "tool_calls",
						index: 0,
					},
				],
				created: TEST_DATE_MS,
				id: "msg_017d9hsprnr9Zu6SQ1zsacKD",
				model: "claude-3-5-sonnet-20241022",
				object: "chat.completion.chunk",
			},
		]

		const stream = await client.chatCompletion(request)
		const receivedChunks: (Completions.ChatCompletionChunk | Completions.ChatCompletionChunkError)[] = []

		for await (const chunk of stream) {
			receivedChunks.push(chunk)
		}

		expect(receivedChunks).toEqual(expectedChunks)
		expect(mockFetch).toHaveBeenCalledWith(
			"https://api.anthropic.com/v1/messages",
			expect.objectContaining({
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					"x-api-key": "test-key",
					"anthropic-version": "2023-06-01",
				},
			}),
		)
	})
})
