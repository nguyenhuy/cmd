/** @type {import('jest').Config} */
export default {
	// Use ts-jest for TypeScript files
	preset: "ts-jest",

	// Test environment
	testEnvironment: "node",

	// File patterns to look for tests
	testMatch: ["**/__tests__/**/*.test.ts", "**/?(*.)+(spec|test).ts"],

	// Module file extensions
	moduleFileExtensions: ["ts", "js", "json", "node"],

	// Transform files - All ts-jest config is now here
	transform: {
		"^.+\\.ts$": [
			"ts-jest",
			{
				useESM: true,
				tsconfig: "tsconfig.json",
			},
		],
	},

	// Coverage settings
	collectCoverage: true,
	coverageDirectory: "coverage",
	coveragePathIgnorePatterns: ["/node_modules/", "/dist/"],

	// Setup files
	setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
	globalSetup: "<rootDir>/jest.globalsetup.js",
	globalTeardown: "<rootDir>/jest.teardown.js",

	// Module name mapper for path aliases
	moduleNameMapper: {
		"^@/(.*)$": "<rootDir>/src/$1",
	},

	// Global settings - removed ts-jest config from here
	globals: {},

	// Test timeout
	testTimeout: 10000,

	// Verbose output
	verbose: true,

	// ESM Support
	extensionsToTreatAsEsm: [".ts"],
}
