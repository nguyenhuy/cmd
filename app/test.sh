#! /bin/bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
CURRENT_DIR="$(pwd)"

cd "${ROOT_DIR}/app"

# Verify that generated code is up to date
echo "Verify that generated code is up to date"
make sync-dependencies
make lint
git diff --exit-code

# Build app
echo "Build app"
xcodebuild -project Xcompanion.xcodeproj -scheme Xcompanion clean build | xcpretty
xcodebuild -project Xcompanion.xcodeproj -scheme 'Xcompanion Extension' clean build | xcpretty

# Run unit tests
echo "Run unit tests"
cd "$ROOT_DIR/app/modules"
swift package clean
swift test -Xswiftc -suppress-warnings

cd "${CURRENT_DIR}"
