#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
	cat <<EOF
Usage: $0 [--verbose|-v] [--quiet|-q] [--force|-f]

Runs the bootstrap sequence for this dotfiles repo.

Currently executes:
  1. bootnvim.sh
  2. linknvim.sh

Flags:
  --verbose, -v   Show info and warning messages
  --quiet,   -q   Suppress all script output
  --force,   -f   Force reinstall / relink where supported
  --help,    -h   Show this help message
EOF
}

ARGS=()

for arg in "$@"; do
	case "$arg" in
		--verbose|-v|--quiet|-q|--force|-f)
			ARGS+=("$arg")
			;;
		--help|-h)
			usage
			exit 0
			;;
		*)
			printf '\033[1;31m[ERR ]\033[0m Unknown argument: %s\n' "$arg" >&2
			usage
			exit 1
			;;
	esac
done

"$SCRIPT_DIR/scripts/bootnvim.sh" "${ARGS[@]}"
"$SCRIPT_DIR/scripts/linknvim.sh" "${ARGS[@]}"
