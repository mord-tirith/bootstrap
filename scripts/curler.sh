#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
URL=""
PROGRAM_NAME=""
DEST_DIR="${HOME}/.local/bin"

log() {
	[ "$QUIET" -eq 1 ] && return 0
	[ "$VERBOSE" -eq 1 ] && printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
	return 0
}

ok() {
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"
	return 0
}

warn() {
	[ "$QUIET" -eq 1 ] && return 0
	[ "$VERBOSE" -eq 1 ] && printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
	return 0
}

err() {
	printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2
	return 0
}

die() {
	err "$*"
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

usage() {
	cat <<EOF
Usage:
  $0 [options] <url> <program-name>

Downloads a file from URL, detects whether it is:
  - an HTML page (fails)
  - a raw executable/script (installs directly)
  - an archive (extracts and installs program-name)

Options:
  -f, --force       Overwrite existing file in ${DEST_DIR}
  -q, --quiet       Suppress normal output
  -v, --verbose     Show extra logs
  -h, --help        Show this help

Examples:
  $0 https://example.com/mytool mytool
  $0 -f https://example.com/releases/mytool.tar.gz mytool
EOF
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--verbose|-v)
				[ "$QUIET" -eq 1 ] && die "Can't use --quiet and --verbose together"
				VERBOSE=1
				shift
				;;
			--quiet|-q)
				[ "$VERBOSE" -eq 1 ] && die "Can't use --verbose and --quiet together"
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
			-*)
				die "Unknown flag: $1"
				;;
			*)
				if [ -z "$URL" ]; then
					URL="$1"
				elif [ -z "$PROGRAM_NAME" ]; then
					PROGRAM_NAME="$1"
				else
					die "Unexpected extra argument: $1"
				fi
				shift
				;;
		esac
	done

	[ -n "$URL" ] || die "Missing URL"
	[ -n "$PROGRAM_NAME" ] || die "Missing program name"
}

ensure_dest_dir() {
	mkdir -p "$DEST_DIR"
}

download_file() {
	local out="$1"
	log "Downloading: $URL"
	curl -fL --retry 3 --retry-all-errors -o "$out" "$URL"
}

detect_type() {
	local file_path="$1"
	file -b "$file_path"
}

is_html() {
	local desc="$1"
	case "$desc" in
		HTML\ document*|XML\ document* )
			return 0
			;;
		*)
			return 1
			;;
	esac
}

is_archive() {
	local desc="$1"
	case "$desc" in
		*gzip\ compressed*|*tar\ archive*|*Zip\ archive\ data*|*POSIX\ tar\ archive*|*bzip2\ compressed*|*XZ\ compressed* )
			return 0
			;;
		*)
			return 1
			;;
	esac
}

extract_archive() {
	local archive="$1"
	local outdir="$2"

	log "Extracting archive into: $outdir"

	case "$(file -b "$archive")" in
		*Zip\ archive\ data*)
			need_cmd unzip
			unzip -q "$archive" -d "$outdir"
			;;
		*)
			need_cmd tar
			tar -xf "$archive" -C "$outdir"
			;;
	esac
}

find_candidate_binary() {
	local search_dir="$1"

	# 1. Exact filename match first
	if [ -f "${search_dir}/${PROGRAM_NAME}" ]; then
		printf '%s\n' "${search_dir}/${PROGRAM_NAME}"
		return 0
	fi

	local found=""
	while IFS= read -r path; do
		if [ "$(basename "$path")" = "$PROGRAM_NAME" ]; then
			found="$path"
			break
		fi
	done < <(find "$search_dir" -type f 2>/dev/null)

	if [ -n "$found" ]; then
		printf '%s\n' "$found"
		return 0
	fi

	# 2. Fallback: executable file with matching basename anywhere
	while IFS= read -r path; do
		found="$path"
		break
	done < <(find "$search_dir" -type f -perm -u+x -name "$PROGRAM_NAME" 2>/dev/null)

	if [ -n "$found" ]; then
		printf '%s\n' "$found"
		return 0
	fi

	return 1
}

install_file() {
	local src="$1"
	local dest="${DEST_DIR}/${PROGRAM_NAME}"

	if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
		die "Destination exists: $dest (use --force to overwrite)"
	fi

	chmod +x "$src" || true

	if command -v install >/dev/null 2>&1; then
		if [ "$FORCE" -eq 1 ]; then
			install -m 755 "$src" "$dest"
		else
			install -m 755 "$src" "$dest"
		fi
	else
		if [ "$FORCE" -eq 1 ]; then
			cp -f "$src" "$dest"
		else
			cp "$src" "$dest"
		fi
		chmod 755 "$dest"
	fi

	ok "Installed ${PROGRAM_NAME} to ${dest}"
}

main() {
	need_cmd curl
	need_cmd file
	need_cmd find

	parse_args "$@"
	ensure_dest_dir

	local tmpdir
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' EXIT

	local download_path="${tmpdir}/download"
	download_file "$download_path"

	local desc
	desc="$(detect_type "$download_path")"
	log "Downloaded file type: $desc"

	if is_html "$desc"; then
		die "URL returned an HTML/XML page, not a downloadable binary/archive"
	fi

	if is_archive "$desc"; then
		local unpack_dir="${tmpdir}/unpack"
		mkdir -p "$unpack_dir"
		extract_archive "$download_path" "$unpack_dir"

		local candidate
		candidate="$(find_candidate_binary "$unpack_dir")" || \
			die "Could not find '${PROGRAM_NAME}' inside extracted archive"

		log "Found candidate binary: $candidate"
		install_file "$candidate"
	else
		log "Treating download as direct executable/script"
		install_file "$download_path"
	fi
}

main "$@"
