#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
NVIM_SOURCE="$REPO_ROOT/config/nvim"
NVIM_TARGET="$XDG_CONFIG_HOME/nvim"

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
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2
	return 0
}

usage() {
	cat <<EOF
Usage: $0 [--force|-f] [--verbose|-v] [--quiet|-q]

Links Neovim config from:
  $NVIM_SOURCE
to:
  $NVIM_TARGET
EOF
}

parse_args() {
	for arg in "$@"; do
		case "$arg" in
			--verbose|-v) VERBOSE=1 ;;
			--quiet|-q) QUIET=1 ;;
			--force|-f) FORCE=1 ;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				err "Unknown argument: $arg"
				usage
				exit 1
				;;
		esac
	done

	if [ "$VERBOSE" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
		err "Cannot use --verbose and --quiet together"
		exit 1
	fi
}

main() {
	parse_args "$@"

	if [ ! -d "$NVIM_SOURCE" ]; then
		err "Neovim source directory not found: $NVIM_SOURCE"
		exit 1
	fi

	mkdir -p "$XDG_CONFIG_HOME"

	if [ -L "$NVIM_TARGET" ]; then
		current_link="$(readlink "$NVIM_TARGET")"
		if [ "$current_link" = "$NVIM_SOURCE" ] && [ "$FORCE" -eq 0 ]; then
			ok "Neovim config already linked correctly."
			ok "Source: $NVIM_SOURCE"
			ok "Target: $NVIM_TARGET"
			exit 0
		fi
	fi

	if [ -e "$NVIM_TARGET" ] || [ -L "$NVIM_TARGET" ]; then
		if [ "$FORCE" -eq 1 ]; then
			log "Removing existing target: $NVIM_TARGET"
			rm -rf -- "$NVIM_TARGET"
		else
			err "Target already exists: $NVIM_TARGET"
			err "Use --force to replace it."
			exit 1
		fi
	fi

	ln -s "$NVIM_SOURCE" "$NVIM_TARGET"

	ok "Linked Neovim config."
	ok "Source: $NVIM_SOURCE"
	ok "Target: $NVIM_TARGET"
}

main "$@"
