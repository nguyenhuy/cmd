export const resetEnv = () => {
	process.env = global.backupEnv
}

export default () => {
	global.backupEnv = { ...process.env }
	delete process.env["LOCAL_SERVER_PROXY"]
}
