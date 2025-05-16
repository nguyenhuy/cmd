#! /bin/bash

# Fail on errors
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
current_dir=$(pwd)

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

xcodebuild archive -project Xcompanion.xcodeproj -scheme Xcompanion -configuration Release -archivePath ./.build/Xcompanion.xcarchive | xcpretty
echo "Xcode archive created at ./.build/Xcompanion.xcarchive"
APPLICATION_PATH="/Applications/Xcompanion.app"

# Kill running app, and replace it
ps aux | grep -i /Applications/Xcompanion.app | grep -v grep | awk '{print $2}' | xargs kill || echo "Xcompanion is not running"

rm -rf "$APPLICATION_PATH"
mv ./.build/Xcompanion.xcarchive/Products/Applications/Xcompanion.app "$APPLICATION_PATH"
echo "App moved to $APPLICATION_PATH"

open "$APPLICATION_PATH" || echo "Failed to open $APPLICATION_PATH"

# undo the project config modifications
git checkout -- "./Xcompanion.debug.xcconfig"
git checkout -- "./Xcompanion Extension/Extension.debug.xcconfig"
git checkout -- "./Xcompanion.xcodeproj/project.pbxproj" # gets modified when building.
git checkout -- "$repo_root/local-server/build.sha256"

cd "$current_dir"
