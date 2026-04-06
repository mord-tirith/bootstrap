#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

BIN_SOURCE_DIR="$REPO_ROOT/bin"
BIN_TARGET_DIR="${HOME}/.local/bin"

log() {
	[ "$QUIET" -eq 1 ] && return 0
	if [ "$VERBOSE" -eq 1 ]; then
		printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
	fi
	return 0
}

ok() {
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"
	return 0
}

warn() {
	[ "$QUIET" -eq 1 ] && return 0
	if [ "$VERBOSE" -eq 1 ]; then
		printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
	fi
	return 0
}

err() {
	printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2
	return 0
}


usage() {
	cat <<EOF
Usage: $0 [--force|-f] [--verbose|-v] [--quiet|-q]

Links binary scripts to .local/bin

--force,	-f		Run with overwrite
--quiet,	-q		Run with no messages
--verbose,	-v		Include logs and warnings

EOF
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--verbose|-v)
				if [ "$QUIET" -eq 1 ]; then
					err "Can't run -q and -v at once"
					exit 1
				fi
				VERBOSE=1
				shift
				;;
			--quiet|-q)
				if [ "$VERBOSE" -eq 1 ]; then
					err "Can't run -v and -q at once"
					exit 1
				fi
				QUIET=1
				shift
				;;
			--force|-f)
				FORCE=1
				shift
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				err "Unknown argument: $1"
				usage
				exit 1
				;;
		esac
	done

}

link_script() {
	local src="$1"
	local name target current_link

	name="$(basename "$src")"
	target="$BIN_TARGET_DIR/$name"

	if [ -L "$target" ]; then
		current_link="$(readlink "$target")"
		if [ "$current_link" = "$src" ] && [ "$FORCE" -eq 0 ]; then
			ok "Already linked: $name"
			return 0
		fi
	fi

	if [ -e "$target" ] || [ -L "$target" ]; then
		if [ "$FORCE" -eq 1 ]; then
			log "Removing existing target: $target"
			rm -rf -- "$target"
		else
			err "Target already exists: $target"
			err "Use --force to replace it"
			exit 1
		fi
	fi

	ln -s "$src" "$target"
	ok "Linked $target -> $src"
}

main() {
	parse_args "$@"

	if [ ! -d "$BIN_SOURCE_DIR" ]; then
		err "Source bin directory not found: $BIN_SOURCE_DIR"
		exit 1
	fi

	mkdir -p "$BIN_TARGET_DIR"

	local found_any=0

	while IFS= read -r -d '' file; do
		found_any=1
		link_script "$file"
	done < <(find "$BIN_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type f -perm -u+x -print0 | sort -z)

	if [ "$found_any" -eq 0 ]; then
		warn "No binaries found in $BIN_SOURCE_DIR"
		exit 0
	fi
}

main "$@"
