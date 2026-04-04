#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
LAUNCH=0

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
KITTY_APP_DIR="$PREFIX/kitty.app"
APPLICATIONS_DIR="$PREFIX/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/kitty.desktop"

log() {
	[ "$QUIET" -eq 1 ] && return 0
	if [ "$VERBOSE" -eq 1 ]; then
		printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
	fi
	return 0
}

ok() {
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;32m[OK]\033[0m %s\n' "$*"
	return 0
}

warn(){
	[ "$QUIET" -eq 1 ] && return 0
	if [ "$VERBOSE" -eq 1 ]; then
		printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
	fi
	return 0
}

err() {
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
	return 0
}

usage() {
	cat <<EOF
Usage: $0 [--verbose|-v] [--quiet|-q] [--force|-f] [--launch|-l] [--help|-h]

Installs or updates kitty to ~/.local/kitty.app,
symlinks ~/.local/bin for kitty use,
and installs ~/.local/share/applications/kitty.desktop

Flags:
  --verbose,	-v	Display info and warning messages
  --quiet,	-q	Hides all output
  --force,	-f	Forces kitty reinstallation
  --launch,	-l	Launches kitty once installation finishes
  --help,	-h	Shows this help message
EOF
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		err "Required command not found: $1"
		exit 1
	}
}

parse_args() {
	for arg in "$@"; do
		case "$arg" in
			--verbose|-v) VERBOSE=1 ;;
			--quiet|-q) QUIET=1 ;;
			--force|-f) FORCE=1 ;;
			--launch|-l) LAUNCH=1 ;;
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
		QUIET=0
		warn "--verbose and --quiet used together"
		warn "--verbose taking precedence"
	fi
}

kitty_exists() {
	[ -x "$KITTY_APP_DIR/bin/kitty" ]
}

install_update_kitty() {
	mkdir -p "$BIN_DIR" "$APPLICATIONS_DIR"

	if kitty_exists; then
		if [ "$FORCE" -eq 0 ]; then
			ok "Kitty already installed"
			return 0
		fi
		if [ "$FORCE" -eq 1 ]; then
			log "--force: reinstalling kitty"
		fi
	else
		log "Installing kitty"
	fi

	if [ "$VERBOSE" -eq 1 ]; then
		curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
	else
		curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin >/dev/null 2>&1
	fi

	if ! kitty_exists; then
		err "Kitty installation failed"
		exit 1
	fi

	ok "Kitty installed at $KITTY_APP_DIR"
}

link_binaries() {
	mkdir -p "$BIN_DIR"

	ln -sfn "$KITTY_APP_DIR/bin/kitty" "$BIN_DIR/kitty"
	ln -sfn "$KITTY_APP_DIR/bin/kitten" "$BIN_DIR/kitten"

	ok "Linked kitty -> $BIN_DIR/kitty"
	ok "Linked kitten -> $BIN_DIR/kitten"
}

install_desktop_file() {
	local icon_path exec_path
	icon_path="$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png"
	exec_path="$KITTY_APP_DIR/bin/kitty"

	mkdir -p "$APPLICATIONS_DIR"

	cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Kitty
Exec=$exec_path
Icon=$icon_path
Type=Application
Categories=System;TerminalEmulator;
Terminal=false
EOF

	ok "Installed kitty launcher at $DESKTOP_FILE"
}

print_summary() {
	ok "Kitty executable:	$KITTY_APP_DIR/bin/kitty"
	ok "Desktop launcher:	$DESKTOP_FILE"
}

launch_kitty() {
	ok "1: entered launch"
	if [ "$LAUNCH" -ne 1 ]; then
		return 0
	fi
	ok "2: launch flag was 1"
	if [ ! -x "$KITTY_APP_DIR/bin/kitty" ]; then
		err "Kitty executable not found"
		exit 1
	fi
	ok "3: found kitty executable"
	log "Launching kitty..."
	setsid kitty >/dev/null 2>&1 &
	exit 0
	ok "4: somehow got past exit 0"
}

main() {
	parse_args "$@"

	need_cmd curl
	need_cmd sh
	need_cmd ln
	need_cmd mkdir
	need_cmd cat

	install_update_kitty
	link_binaries
	install_desktop_file
	print_summary
	launch_kitty
}

main "$@"
