#!/bin/bash
set -euo pipefail

# When run as a build phase in Xcode, the environment is not set up correctly.
# Add Homebrew to the path to support yarn.
export PATH="$PATH:/opt/homebrew/bin"

file_directory="$(realpath "$(dirname "$0")")"

PROXY_HASH_FILE="$file_directory/../local-server/build.sha256"
APP_HASH_FILE="$file_directory/../app/modules/services/ServerService/Sources/Resources/build.sha256"

copy_one_file() {
	local file_path="$1"
	local destination_dir="$2"
	mkdir -p "$destination_dir"
	destination_path="$destination_dir/$(basename "$file_path")"
	echo "cp \"$file_path\" \"$destination_path\""
	cp "$file_path" "$destination_path"
}

build_and_copy() {
	(cd "$file_directory/../local-server" && yarn build) || exit 1

	files_to_copy=(
		"$file_directory/../local-server/dist/main.bundle.js"
		"$file_directory/../local-server/dist/main.bundle.js.map"
		"$file_directory/../local-server/build.sha256"
	)
	destination_dir=(
		"$file_directory/../app/modules/services/ServerService/Sources/Resources"
		"$HOME/Library/Application\ Support/XCompanion"
	)
	for file in "${files_to_copy[@]}"; do
		for destination in "${destination_dir[@]}"; do
			copy_one_file "$file" "$destination"
		done
	done
	# When run from Xcode as a build phase, this is executed after the files are copied from the package's bundle.
	# So we need to exit with a non-zero exit code to indicate that the build needs to be restarted.
	echo "The local server has been updated. Please restart the build." >&2
	exit 1
}

# Sync the schema
(cd "$file_directory/../local-server" && yarn export-schema-swift) || exit 1

# Check if the app hash file exists
if [ ! -f "$APP_HASH_FILE" ]; then
	echo "App hash file $APP_HASH_FILE doesn't exist. Running build..."
	build_and_copy
fi

# Compare the hash files
if ! cmp -s "$PROXY_HASH_FILE" "$APP_HASH_FILE"; then
	echo "Build hashes differ. Running build..."
	build_and_copy
else
	echo "Build is up to date."
fi
