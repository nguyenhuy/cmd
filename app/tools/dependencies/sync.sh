#! /bin/bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
CURRENT_DIR="$(pwd)"

cd "${ROOT_DIR}/app/tools/dependencies"

# Cache the built binary, as for some reasons it gets rebuilt every time otherwise.
# The cache will need to be manually cleaned if the binary is updated.
if [ ! -f "./tmp/bin/sync-package-dependencies" ]; then
	swift build -c release
	mkdir -p tmp
	mkdir -p tmp/bin
	cp ".build/release/SyncPackageDependenciesCommand" "./tmp/bin/sync-package-dependencies"
fi
./tmp/bin/sync-package-dependencies sync --path "${ROOT_DIR}/app/modules/Package.swift"

cd "${ROOT_DIR}/app"

# lint
mkdir -p .build/caches/swiftformat
swiftformat --config rules.swiftformat ./**/Module.swift ./**/Package.swift --cache .build/caches/swiftformat

cd "${CURRENT_DIR}"
