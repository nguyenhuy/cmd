#! /bin/bash

# Fail on errors
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
current_dir=$(pwd)

echo "Performing cleanup..."
cd "$repo_root/app"
# Ensure that the project config modifications are undone
git checkout -- "./command.debug.xcconfig" || true
git checkout -- "./command Extension/Extension.debug.xcconfig" || true
git checkout -- "./command.xcodeproj/project.pbxproj" || true # gets modified when building.
git checkout -- "$repo_root/local-server/build.sha256" || true
cd "$current_dir"
