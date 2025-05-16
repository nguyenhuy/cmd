export const toSnakeCase = (str: string): string =>
	str
		.replace(/([A-Z])/g, "_$1")
		.toLowerCase()
		.replace(/^_/, "")

export const toCamelCase = (str: string): string =>
	str
		.replace(/[_\s](.)/g, function ($1) {
			return $1.slice(1).toUpperCase()
		})
		.replace(/[_\s]/g, "")
		.replace(/^(.)/, function ($1) {
			return $1.toLowerCase()
		})

export const toPascalCase = (str: string): string =>
	toCamelCase(str).replace(/^[a-z]/, function ($1) {
		return $1.toUpperCase()
	})
