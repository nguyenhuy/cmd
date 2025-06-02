#!/bin/bash

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
		# Kill Xcode.
		pkill -x "Xcode"
	fi
}

focus_dependency_command() {
	close_xcode
	# Reset xcode state
	find . -path '*.xcuserstate' 2>/dev/null | git check-ignore --stdin | xargs -I{} rm {}

	./tools/dependencies/focus.sh "$@"
	echo "👉 Don't forget to use 'cmd clean' before re-opening the app's xcodeproj"
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
		git check-ignore --stdin |
			while read file; do rm -rf "$file"; done
	# Reset xcode state
	cd "$(git rev-parse --show-toplevel)/app" &&
		find . -path '*.xcuserstate' 2>/dev/null | git check-ignore --stdin | xargs -I{} rm {}
}

test_swift_command() {
	cd modules && swift test -Xswiftc -suppress-warnings --quiet
	clean_command
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
	clean_command
	;;
sync:dependencies)
	sync_dependencies_command "$@"
	;;
focus)
	focus_dependency_command "$@"
	;;
build:release)
	# build the app for release.
	# use --archive to also archive the app.
	build_release_command "$@"
	;;
clean)
	# clean artifacts that might make Xcode behave weirdly and not showing files in the file hierarchy.
	clean_command "$@"
	;;
*)
	echo "Command not found: $command"
	exit 1
	;;
esac
