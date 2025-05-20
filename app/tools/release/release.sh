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
	# Ensure that the project config modifications are undone
	git checkout -- "./Xcompanion.debug.xcconfig" || true
	git checkout -- "./Xcompanion Extension/Extension.debug.xcconfig" || true
	git checkout -- "./Xcompanion.xcodeproj/project.pbxproj" || true # gets modified when building.
	git checkout -- "$repo_root/local-server/build.sha256" || true
	cd "$current_dir"
	echo "Cleanup completed"
}

# Set trap to ensure cleanup happens on exit, regardless of how the script exits
trap cleanup EXIT

if [ -z "$repo_root" ]; then
	echo "Not a git repository"
	exit 1
fi

## verify that there is no un-committed changes, if so this will log the diff and exit
git diff --exit-code

## build the local server for production
cd "$repo_root/local-server"
yarn build:prod

## build the app
cd "$repo_root/app"

./tools/release/configure_xcodeproj_for_release_build.sh

if [ "$ARCHIVE" = true ]; then
	xcodebuild archive -project Xcompanion.xcodeproj -scheme Xcompanion -configuration Release -archivePath ./.build/Xcompanion.xcarchive | xcpretty
	echo "Xcode archive created at ./.build/Xcompanion.xcarchive"
	APPLICATION_PATH="/Applications/Xcompanion.app"

	# Kill running app, and replace it
	ps aux | grep -i /Applications/Xcompanion.app | grep -v grep | awk '{print $2}' | xargs kill || echo "Xcompanion is not running"

	rm -rf "$APPLICATION_PATH"
	mv ./.build/Xcompanion.xcarchive/Products/Applications/Xcompanion.app "$APPLICATION_PATH"
	echo "App moved to $APPLICATION_PATH"

	open "$APPLICATION_PATH" || echo "Failed to open $APPLICATION_PATH"
else
	xcodebuild build -project Xcompanion.xcodeproj -scheme Xcompanion -configuration Release | xcpretty
	echo "Release build completed"
fi

cd "$current_dir"
