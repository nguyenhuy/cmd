export interface ListFilesToolInput {
	projectRoot: string
	path: string
	recursive?: boolean
	breadthFirstSearch?: boolean
	/**
	 * @format integer
	 */
	limit?: number
}

export interface ListFilesToolOutput {
	files: ListedFileInfo[]
}

export interface ListedFileInfo {
	path: string
	isFile: boolean
	isDirectory: boolean
	hasMoreContent?: boolean
	isSymlink: boolean
	/**
	 * @format integer
	 */
	byteSize: number
	permissions: string
	createdAt: Date
	modifiedAt: Date
}
