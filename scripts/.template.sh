#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0

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
Usage: $0 [--force|-f] [--verbose|-v] [--quiet|-q]

INSERT DESCRIPTION HERE

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
