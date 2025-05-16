#! /bin/bash

# Fail on errors
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

if [ -z "$repo_root" ]; then
    echo "Not a git repository"
    exit 1
fi

# Modify the project config, as Xcode is unable to build the project when the Xcode extension target
# has different names between DEBUG and RELEASE.
sed -i '' 's/ $(DEBUG_SUFFIX)//' "$repo_root/app/Xcompanion.debug.xcconfig"
sed -i '' 's/ $(DEBUG_SUFFIX)//' "$repo_root/app/Xcompanion Extension/Extension.debug.xcconfig"
