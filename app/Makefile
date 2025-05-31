# lint
lint:
	@mkdir -p .build/caches/swiftformat && \
	swiftformat --config rules-header.swiftformat . && \
	swiftformat --config rules.swiftformat . --cache .build/caches/swiftformat
# Sync module dependencies
sync-dependencies:
	@./tools/dependencies/sync.sh
# Sync module dependencies, including local Package.swift files (this might make Xcode behave unexpectedly when working on the main app)
sync-all-dependencies:
	@./tools/dependencies/sync.sh --all
# Create a release build, and update the one installed locally
build_release:
	@./tools/release/release.sh
# Create a release build, and update the one installed locally
archive_release:
	@./tools/release/release.sh --archive
# Remove tmp files that might lead to Xcode not showing Swift packages content
clean:
	@cd "$(shell git rev-parse --show-toplevel)/app/modules" && \
	swift package clean && \
	find . -not -path './.git/*' 2> /dev/null | \
	git check-ignore --stdin | \
	while read file; do rm -rf "$$file"; done; \
	cd "$(shell git rev-parse --show-toplevel)/app" && \
	find . -path '*.xcuserstate' 2> /dev/null | git check-ignore --stdin | xargs -I{} rm {}
test:
	@cd modules && swift test -Xswiftc -suppress-warnings --quiet
