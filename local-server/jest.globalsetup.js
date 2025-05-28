export const resetEnv = () => {
	process.env = global.backupEnv
}

export default () => {
	global.backupEnv = { ...process.env }
	delete process.env["ANTHROPIC_LOCAL_SERVER_PROXY"]
	delete process.env["OPEN_ROUTER_LOCAL_SERVER_PROXY"]
	delete process.env["OPENAI_LOCAL_SERVER_PROXY"]
}
