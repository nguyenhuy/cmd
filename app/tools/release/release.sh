#! /bin/bash

# Fail on errors
set -euo pipefail

# Parse arguments
ARCHIVE=false
for arg in "$@"; do
	case $arg in
	--archive)
		ARCHIVE=true
		shift
		;;
	esac
done

repo_root=$(git rev-parse --show-toplevel)
current_dir=$(pwd)

# Define cleanup function
cleanup() {
	echo "Performing cleanup..."
	cd "$repo_root/app"
	./tools/release/cleanup_xcodeproj_after_release_build.sh
}

# Set trap to ensure cleanup happens on exit, regardless of how the script exits
trap cleanup EXIT

if [ -z "$repo_root" ]; then
	echo "Not a git repository"
	exit 1
fi

## verify that there is no un-committed changes, if so this will log the diff and exit
git diff --exit-code

## build the app
cd "$repo_root/app"

./tools/release/configure_xcodeproj_for_release_build.sh

if [ "$ARCHIVE" = true ]; then
	xcodebuild archive -project command.xcodeproj -scheme command -configuration Release -archivePath ./.build/command.xcarchive | xcpretty
	echo "Xcode archive created at ./.build/command.xcarchive"
	APPLICATION_PATH="/Applications/command.app"

	# Kill running app, and replace it
	ps aux | grep -i /Applications/command.app | grep -v grep | awk '{print $2}' | xargs kill || echo "command is not running"

	rm -rf "$APPLICATION_PATH"
	mv ./.build/command.xcarchive/Products/Applications/command.app "$APPLICATION_PATH"
	echo "App moved to $APPLICATION_PATH"

	open "$APPLICATION_PATH" || echo "Failed to open $APPLICATION_PATH"
else
	xcodebuild build -project command.xcodeproj -scheme command -configuration Release
	echo "Release build completed"
fi

cd "$current_dir"
