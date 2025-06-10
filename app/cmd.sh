#!/bin/bash

ROOT_DIR="$(git rev-parse --show-toplevel)"
current_dir=$(pwd)
cd "$ROOT_DIR/app"

reset() {
	cd $current_dir
}
trap reset EXIT

lint_swift_command() {
	mkdir -p .build/caches/swiftformat &&
		swiftformat --config rules-header.swiftformat . &&
		swiftformat --config rules.swiftformat . --cache .build/caches/swiftformat
}

sync_dependencies_command() {
	./tools/dependencies/sync.sh "$@"
}

close_xcode() {
	if pgrep -x "Xcode" >/dev/null; then
		# Kill Xcode
		pkill -x "Xcode"
		# Wait for Xcode to close
		while pgrep -x "Xcode" >/dev/null; do
			sleep 0.01
		done
	fi
}

focus_dependency_command() {
	close_xcode
	# Reset xcode state
	find . -path '*.xcuserstate' 2>/dev/null | git check-ignore --stdin | xargs -I{} rm {}

	./tools/dependencies/focus.sh "$@"
	echo "👉 Don't forget to use 'cmd open:app' the next time you re-open the app's xcodeproj, instead of opening it manually."
}

build_release_command() {
	./tools/release/release.sh "$@"
}

clean_command() {
	close_xcode
	# Remove derived files from swift packages
	cd "$(git rev-parse --show-toplevel)/app/modules" &&
		swift package clean &&
		find . -not -path './.git/*' 2>/dev/null |
		# Don't remove files in ./services/ServerService/Sources/Resources
		grep -v 'services/ServerService/Sources/Resources' |
			# Remove all git-ignored files
			git check-ignore --stdin |
			while read file; do rm -rf "$file"; done
	# Reset xcode state
	cd "$(git rev-parse --show-toplevel)/app" &&
		find . -path '*.xcuserstate' 2>/dev/null | git check-ignore --stdin | xargs -I{} rm {}
}

test_swift_command() {
	cd modules && swift test -Xswiftc -suppress-warnings --quiet
}

# Main command dispatcher
command=$1
shift

case "$command" in
lint:swift)
	lint_swift_command "$@"
	;;
test:swift)
	test_swift_command "$@"
	;;
sync:dependencies)
	sync_dependencies_command "$@"
	;;
focus)
	focus_dependency_command "$@"
	;;
open:app)
	clean_command &&
		xcode_path=$(xcode-select -p) &&
		xcode_path="${xcode_path%%.app*}.app" &&
		open -a "$xcode_path" "./command.xcodeproj" --args -ApplePersistenceIgnoreState YES
	;;
build:release)
	# build the app for release.
	# use --archive to also archive the app.
	build_release_command "$@"
	;;
clean)
	# clean artifacts that might make Xcode behave weirdly and not showing files in the file hierarchy.
	clean_command
	;;
watch)
	# Watch file changes, and update derived files when necessary.
	cd "$ROOT_DIR/local-server" && yarn watch
	;;
*)
	echo "Command not found: $command"
	exit 1
	;;
esac
