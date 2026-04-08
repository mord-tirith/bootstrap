#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
URL=""
PROGRAM_NAME=""
DEST_DIR="${HOME}/.local/bin"
WORK_DIR=""
TEMP_DIR=1
MAN_DIR="${HOME}/.local/share/man"

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
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || err "Missing required command: $1"
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
  --force,		-f	Overwrite existing file in ${DEST_DIR}
  -quiet,		-q	Suppress normal output
  --verbose,	-v	Show extra logs
  --workdir,	-w	Name a path for the download to go into
					instead of a tempdir
  --help,		-h	Show this help

Examples:
  $0 https://example.com/mytool mytool
  $0 -f https://example.com/releases/mytool.tar.gz mytool
  $0 https://example.com/mytool mytool -w ~/Desktop
EOF
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--verbose|-v)
				VERBOSE=1
				shift
				;;
			--quiet|-q)
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
			--workdir|-w)
				[ "$#" -ge 2 ] || err "--workdir expects a path"
				TEMP_DIR=0
				WORK_DIR="$2"
				shift 2
				;;
			-*)
				err "Unknown flag: $1"
				;;
			*)
				if [ -z "$URL" ]; then
					URL="$1"
				elif [ -z "$PROGRAM_NAME" ]; then
					PROGRAM_NAME="$1"
				else
					err "Unexpected extra argument: $1"
				fi
				shift
				;;
		esac
	done

	[ -n "$URL" ] || err "Missing URL"
	[ -n "$PROGRAM_NAME" ] || err "Missing program name"
	if [ "$VERBOSE" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
		QUIET=0
		warn "Both --quiet and --verbose detected; defaulting to --verbose"
	fi
}

install_man_pages_from_dir() {
	local search_dir="$1"
	local found=0
	local path
	local base
	local section
	local target_dir

	while IFS= read -r path; do
		base="$(basename "$path")"

		case "$base" in
			*.1|*.2|*.3|*.4|*.5|*.6|*.7|*.8|*.9)
				section="${base##*.}"
				;;
			*.1.gz|*.2.gz|*.3.gz|*.4.gz|*.5.gz|*.6.gz|*.7.gz|*.8.gz|*.9.gz)
				section="$(printf '%s' "$base" | sed -E 's/.*\.([1-9])\.gz/\1/')"
				;;
			*)
				continue
				;;
		esac

		target_dir="${MAN_DIR}/man${section}"
		mkdir -p "$target_dir"
		cp "$path" "${target_dir}/"
		found=1
		log "Installed man page: ${target_dir}/${base}"
	done < <(
		find "$search_dir" -type f \
			\( -name "${PROGRAM_NAME}.[1-9]" -o -name "${PROGRAM_NAME}.[1-9].gz" \) \
			2>/dev/null
	)

	if [ "$found" -eq 1 ]; then
		ok "Installed manual pages to ${MAN_DIR}"
	else
		log "No manual pages found for ${PROGRAM_NAME}"
	fi
}

ensure_dest_dir() {
	mkdir -p "$DEST_DIR"
}

download_file() {
	local out="$1"
	log "Downloading: $URL"

	if [ "$VERBOSE" -eq 1 ]; then
		curl -fL --retry 3 --retry-all-errors -# -o "$out" "$URL"
	else
		curl -fsSL --retry 3 --retry-all-errors -o "$out" "$URL"
	fi
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
	local found=""

	if [ -f "${search_dir}/${PROGRAM_NAME}" ] && [ -x "${search_dir}/${PROGRAM_NAME}" ]; then
		printf '%s\n' "${search_dir}/${PROGRAM_NAME}"
		return 0
	fi

	found="$(find "$search_dir" -type f -name "$PROGRAM_NAME" -perm -u+x 2>/dev/null | head -n 1)" || true
	if [ -n "$found" ]; then
		printf '%s\n' "$found"
		return 0
	fi

	found="$(find "$search_dir" -type f -name "$PROGRAM_NAME" 2>/dev/null | head -n 1)" || true
	if [ -n "$found" ]; then
		printf '%s\n' "$found"
		return 0
	fi

	found="$(find "$search_dir" -type f -name "${PROGRAM_NAME}.sh" 2>/dev/null | head -n 1)" || true
	if [ -n "$found" ]; then
		printf '%s\n' "$found"
		return 0
	fi

	return 1
}

find_make_dir() {
	local dir="$1"
	local makefile

	makefile="$(find "$dir" -type f \( -name Makefile -o -name makefile \) 2>/dev/null | head -n 1)" || true
	[ -n "$makefile" ] || return 1
	dirname "$makefile"
}

install_make_from_dir() {
	local	dir="$1"
	local	build_dir
	local	candidate

	need_cmd make

	build_dir="$(find_make_dir "$dir")" || \
		err "Found install type 'make' but no Makefile directory could be found"

	log "Building with make in: $build_dir"

	(
		cd "$build_dir"
		if [ "$VERBOSE" -eq 1 ]; then
			make
		elif [ "$QUIET" -eq 1 ]; then
			make >/dev/null 2>&1
		else
			if ! make >/dev/null 2>&1; then
				make || true
				err "Build failed"
			fi
		fi
	)

	candidate="$(find_candidate_binary "$dir")" || \
		err "Build completed, but could not find binary '${PROGRAM_NAME}'"

	log "Built binary candidate: $candidate"
	install_file "$candidate"
	install_man_pages_from_dir "$dir"
}

install_binary_from_dir() {
	local	dir="$1"
	local	candidate

	candidate="$(find_candidate_binary "$dir")" || \
		err "Could not find binary '${PROGRAM_NAME}'"

	log "Found binary candidate: $candidate"
	install_file "$candidate"
	install_man_pages_from_dir "$dir"
}

install_file() {
	local src="$1"
	local dest="${DEST_DIR}/${PROGRAM_NAME}"

	if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
		err "Destination exists: $dest (use --force to overwrite)"
	fi

	chmod +x "$src" || true

	if command -v install >/dev/null 2>&1; then
		install -m 755 "$src" "$dest"
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

detect_install_type() {
	local	dir="$1"

	if find "$dir" -type f -name "$PROGRAM_NAME" -perm -u+x 2>/dev/null | grep -q .; then
		printf 'binary\n'
		return 0
	elif find "$dir" -type f -name "${PROGRAM_NAME}.sh" 2>/dev/null | grep -q .; then
		printf 'script\n'
		return 0
	elif find "$dir" -type f \( -name Makefile -o -name makefile \) | grep -q .; then
		printf 'make\n'
		return 0
	else
		printf 'unknown\n'
		return 0
	fi

}

safe_name() {
	printf '%s' "$1" | tr -cs '[:alnum:]._-' '_'
}

make_workspace_dir() {
	local	base_dir="$1"
	local	stamp
	local	safe_prog


	stamp="$(date +%Y%m%d_%H%M%S)"
	safe_prog="$(safe_name "$PROGRAM_NAME")"
	printf '%s/%s_install_%s\n' "$base_dir" "$safe_prog" "$stamp"
}

dispatch_install() {
	local	install_type="$1"
	local	work_dir="$2"

	case "$install_type" in
		binary|script)
			install_binary_from_dir "$work_dir"
			;;
		make)
			install_make_from_dir "$work_dir"
			;;
		unknown)
			err "Could not determine how to install '${PROGRAM_NAME}'"
			;;
		*)
			err "Unknown install type: $install_type"
			;;
	esac
}

prepare_work_dir() {
	local	download_path="$1"
	local	desc="$2"
	local	work_dir="$3"

	rm -rf "$work_dir"
	mkdir -p "$work_dir"

	if is_archive "$desc"; then
		extract_archive "$download_path" "$work_dir"
	else
		cp "$download_path" "${work_dir}/"
	fi
}

setup_workspace() {
	if [ "$TEMP_DIR" -eq 1 ]; then
		WORK_DIR="$(mktemp -d)"
		trap 'rm -rf "$WORK_DIR"' EXIT
	else
		mkdir -p "$WORK_DIR"
		WORK_DIR="$(make_workspace_dir "$WORK_DIR")"
		mkdir -p "$WORK_DIR"
	fi
}

main() {
	need_cmd curl
	need_cmd file
	need_cmd find

	parse_args "$@"
	ensure_dest_dir
	setup_workspace

	local download_path="${WORK_DIR}/download"
	local stage_dir="${WORK_DIR}/work"

	download_file "$download_path"

	local desc
	desc="$(detect_type "$download_path")"
	log "Downloaded file type: $desc"

	if is_html "$desc"; then
		err "URL returned an HTML/XML page, not a downloadable file"
	fi

	prepare_work_dir "$download_path" "$desc" "$stage_dir"

	local install_type
	install_type="$(detect_install_type "$stage_dir")"
	log "Detected install type: $install_type"

	dispatch_install "$install_type" "$stage_dir"
}

main "$@"
