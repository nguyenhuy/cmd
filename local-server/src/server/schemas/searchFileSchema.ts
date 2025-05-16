export interface SearchFilesToolInput {
	projectRoot: string
	directoryPath: string
	regex: string
	filePattern?: string
}

export interface SearchFilesToolOutput {
	outputForLLm: string
	results: SearchFileResult[]
	rootPath: string
	hasMore: boolean
}
export interface SearchFileResult {
	path: string
	searchResults: SearchResult[]
}

export interface SearchResult {
	/**
	 * @format integer
	 */
	line: number
	text: string
	isMatch: boolean
}
