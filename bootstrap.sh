#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
UNINSTALL=0

ORIG_ARGS=("$@")
FORWARDED_ARGS=()

CURRENT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.dotfiles"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

KITTY_CONFIG_SOURCE="$INSTALL_DIR/config/kitty"
KITTY_CONFIG_TARGET="$XDG_CONFIG_HOME/kitty"
KITTY_THEME_TARGET="$KITTY_CONFIG_TARGET/current-theme.conf"

ZSH_CONFIG_SOURCE="$INSTALL_DIR/zsh"
ZSH_CONFIG_TARGET="$XDG_CONFIG_HOME/zsh"
ZSH_LOADER_TARGET="$HOME/.zshrc"

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
	exit 1
}

usage() {
	cat <<EOF
Usage: $0 [--verbose|-v] [--quiet|-q] [--force|-f] [--uninstall|-u] [--help|-h]

Installs this repository into ~/.dotfiles and bootstraps:
  - kitty
  - neovim
  - repo bin/ commands
  - kitty config
  - zsh config

Flags:
  --verbose,   -v   Show info and warning messages
  --quiet,     -q   Suppress normal output
  --force,     -f   Overwrite/reinstall where supported
  --uninstall, -u   Run uninstall script and exit
  --help,      -h   Show this help

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
				FORWARDED_ARGS+=("$1")
				shift
				;;
			--quiet|-q)
				if [ "$VERBOSE" -eq 1 ]; then
					err "Can't run -v and -q at once"
					exit 1
				fi
				QUIET=1
				FORWARDED_ARGS+=("$1")
				shift
				;;
			--force|-f)
				FORCE=1
				FORWARDED_ARGS+=("$1")
				shift
				;;
			--uninstall|-u)
				UNINSTALL=1
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

run_step() {
	local script="$1"
	shift

	if [ ! -x "$script" ]; then
		err "Script not executable or missing: $script"
		exit 1
	fi

	log "Running: $(basename "$script")"
	"$script" "${FORWARDED_ARGS[@]}" "$@"
}

sync_repo_into_dotfiles() {
	if [ "$CURRENT_ROOT" = "$INSTALL_DIR" ]; then
		return 0
	fi

	log "Installing repo into $INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"
	cp -a "$CURRENT_ROOT"/. "$INSTALL_DIR"/

	ok "Repository installed to $INSTALL_DIR"
	log "Re-launching bootstrap from installed repo"

	exec "$INSTALL_DIR/bootstrap.sh" "${ORIG_ARGS[@]}"
}

link_dir() {
	local src="$1"
	local dst="$2"
	local current_link

	if [ ! -d "$src" ]; then
		err "Source directory not found: $src"
		exit 1
	fi

	mkdir -p "$(dirname "$dst")"

	if [ -L "$dst" ]; then
		current_link="$(readlink "$dst")"
		if [ "$current_link" = "$src" ] && [ "$FORCE" -eq 0 ]; then
			ok "Already linked: $dst"
			return 0
		fi
	fi

	if [ -e "$dst" ] || [ -L "$dst" ]; then
		if [ "$FORCE" -eq 1 ]; then
			log "Removing existing target: $dst"
			rm -rf -- "$dst"
		else
			err "Target already exists: $dst"
			err "Use --force to replace it"
			exit 1
		fi
	fi

	ln -s "$src" "$dst"
	ok "Linked $dst -> $src"
}

write_zsh_loader() {
	local expected='source "$HOME/.config/zsh/rc.zsh"'

	if [ -f "$ZSH_LOADER_TARGET" ] && [ "$FORCE" -eq 0 ]; then
		if grep -qxF "$expected" "$ZSH_LOADER_TARGET"; then
			ok "Zsh loader already correct: $ZSH_LOADER_TARGET"
			return 0
		fi
		err "Target already exists: $ZSH_LOADER_TARGET"
		err "Use --force to replace it"
		exit 1
	fi

	cat > "$ZSH_LOADER_TARGET" <<'EOF'
source "$HOME/.config/zsh/rc.zsh"
EOF

	ok "Wrote zsh loader to $ZSH_LOADER_TARGET"
}

ensure_kitty_theme_file() {
	if [ -f "$KITTY_THEME_TARGET" ] && [ "$FORCE" -eq 0 ]; then
		return 0
	fi

	cat > "$KITTY_THEME_TARGET" <<'EOF'
foreground            #f8f8f2
background            #282a36
selection_foreground  #f8f8f2
selection_background  #44475a
cursor                #f8f8f2
cursor_text_color     #282a36

color0  #21222c
color1  #ff5555
color2  #50fa7b
color3  #f1fa8c
color4  #bd93f9
color5  #ff79c6
color6  #8be9fd
color7  #f8f8f2
color8  #6272a4
color9  #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff
EOF

	ok "Wrote default kitty theme to $KITTY_THEME_TARGET"
}

link_kitty_config() {
	link_dir "$KITTY_CONFIG_SOURCE" "$KITTY_CONFIG_TARGET"
	ensure_kitty_theme_file
}

link_zsh_config() {
	link_dir "$ZSH_CONFIG_SOURCE" "$ZSH_CONFIG_TARGET"
	write_zsh_loader
}

prep_state_manager() {
	local sm="$INSTALL_DIR/scripts/state_manager.sh"

	$("$sm" -b -q)
	$("$sm" --boot-colors -q)
	ok "Installed state manager json file"
}

main() {
	parse_args "$@"

	if [ "$UNINSTALL" -eq 1 ]; then
		exec "$CURRENT_ROOT/scripts/uninstall.sh" "${FORWARDED_ARGS[@]}"
	fi

	sync_repo_into_dotfiles

	prep_state_manager
	run_step "$INSTALL_DIR/scripts/bootkitty.sh"

	link_zsh_config
	link_kitty_config

	run_step "$INSTALL_DIR/scripts/bootnvim.sh"
	run_step "$INSTALL_DIR/scripts/linknvim.sh"
	run_step "$INSTALL_DIR/scripts/linkbin.sh"
	run_step "$INSTALL_DIR/scripts/packages.sh"


	ok "Bootstrap complete"
	ok "Repo: $INSTALL_DIR"
}

main "$@"
