export interface ListFilesToolInput {
	projectRoot: string
	path: string
	recursive?: boolean
	limit?: number
}

export interface ListFilesToolOutput {
	files: ListedFileInfo[]
	hasMore: boolean
}

export interface ListedFileInfo {
	path: string
	isFile: boolean
	isDirectory: boolean
	isSymlink: boolean
	/**
	 * @format integer
	 */
	byteSize: number
	permissions: string
	createdAt: Date
	modifiedAt: Date
}
