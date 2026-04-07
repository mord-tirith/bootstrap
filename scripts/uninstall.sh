#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
PURGE_REPO=0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

TO_CLEAN_DIRS=(
	"$HOME/.zshrc"
	"$HOME/.config/zsh"
	"$HOME/.cache/nvim"
	"$HOME/.config/nvim"
	"$HOME/.local/opt/nvim"
	"$HOME/.local/bin/nvim"
	"$HOME/.local/kitty.app"
	"$HOME/.local/bin/kitty"
	"$HOME/.local/share/nvim"
	"$HOME/.local/state/nvim"
	"$HOME/.local/bin/kitten"
	"$HOME/.local/share/applications/kitty.desktop"
)

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

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		err "Missing required command: $1"
		exit 1
	}
}

usage() {
	cat <<EOF
Usage: $0 [--verbose|-v] [--quiet|-q] [--purge|-p]

Removes all files installed by the bootstrap,
except for the repository itself

--quiet,	-q		Run with no messages
--verbose,	-v		Include logs and warnings
--purge,	-p		Delete repo during uninstall

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
			--help|-h)
				usage
				exit 0
				;;
			--purge|-p)
				PURGE_REPO=1
				shift
				;;
			*)
				err "Unknown argument: $1"
				usage
				exit 1
				;;
		esac
	done
}

remove_linked_bin() {
	local src_dir="$REPO_ROOT/bin"
	local target_dir="$HOME/.local/bin"
	local file name target current_link

	[ -d "$src_dir" ] || return 0

	while IFS= read -r -d '' file; do
		name="$(basename "$file")"
		target="$target_dir/$name"

		if [ -L "$target" ]; then
			current_link="$(readlink "$target")"
			if [ "$current_link" = "$file" ]; then
				log "Removing linked bin: $target"
				rm -f -- "$target"
				ok "Removed $target"
			fi
		fi
	done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type f -print0)
}

remove_one() {
	local path="$1"

	if [ -L "$path" ] || [ -e "$path" ]; then
		log "Removing $path"
		rm -rf -- "$path"
		ok "Removed $path"
	else
		warn "Not found: $path"
	fi
}

main() {
	parse_args "$@"

	log "Removing files"
	for path in "${TO_CLEAN_DIRS[@]}"; do
		remove_one "$path"
	done

	log "Removing bin symlinks"
	remove_linked_bin

	if [ "$PURGE_REPO" -eq 1 ]; then
		log "Removed repository"
		remove_one "$REPO_ROOT"
	fi

	ok "Uninstall complete"
	exit 0
}

main "$@"
