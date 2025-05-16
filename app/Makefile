# lint
lint:
	@swiftformat --config rules.swiftformat .
# Sync module dependencies
sync-dependencies:
	@./tools/dependencies/sync.sh
# Create a release build, and update the one installed locally
release:
	@./tools/release/release.sh
# Remove tmp files that might lead to Xcode not showing Swift packages content
cleanup:
	@cd "$(shell git rev-parse --show-toplevel)/app/modules" && \
	find . -not -path './.git/*' | \
	git check-ignore --stdin | \
	tr '\n' '\0' | \
	xargs -0 rm -rf
