#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
UNINSTALL=0
INSIDE_KITTY=0

ORIG_ARGS=("$@")
FORWARDED_ARGS=()

CURRENT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.dotfiles"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

KITTY_CONFIG_SOURCE="$INSTALL_DIR/config/kitty"
KITTY_CONFIG_TARGET="$XDG_CONFIG_HOME/kitty"

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
	return 0
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

Internal:
  --inside-kitty    Continue bootstrap from inside kitty
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
			--inside-kitty)
				INSIDE_KITTY=1
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

has_gui() {
	[ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]
}

relaunch_inside_kitty() {
	local kitty_bin="$HOME/.local/bin/kitty"

	if [ "$INSIDE_KITTY" -eq 1 ]; then
		return 0
	fi

	if ! has_gui; then
		warn "No GUI session detected; continuing in current terminal"
		return 0
	fi

	if [ ! -x "$kitty_bin" ]; then
		warn "Kitty not found after install; continuing in current terminal"
		return 0
	fi

	log "Relaunching bootstrap inside kitty"
	"$kitty_bin" --detach "$INSTALL_DIR/bootstrap.sh" --inside-kitty "${FORWARDED_ARGS[@]}"
	exit 0
}

link_dir() {
	local src="$1"
	local dst="$2"

	if [ ! -d "$src" ]; then
		err "Source directory not found: $src"
		exit 1
	fi

	mkdir -p "$(dirname "$dst")"

	if [ -L "$dst" ]; then
		local current_link
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

link_kitty_config() {
	link_dir "$KITTY_CONFIG_SOURCE" "$KITTY_CONFIG_TARGET"
}

link_zsh_config() {
	if [ ! -f "$HOME/.zshrc" ]; then
	       touch "$HOME/.zshrc"
	fi
	link_dir "$ZSH_CONFIG_SOURCE" "$ZSH_CONFIG_TARGET"
	write_zsh_loader
}

main() {
	parse_args "$@"

	if [ "$UNINSTALL" -eq 1 ]; then
		exec "$CURRENT_ROOT/scripts/uninstall.sh" "${FORWARDED_ARGS[@]}"
	fi

	sync_repo_into_dotfiles

	# install kitty first so the binary exists
	run_step "$INSTALL_DIR/scripts/bootkitty.sh"

	# prepare shell + kitty config BEFORE relaunching inside kitty
	link_zsh_config
	link_kitty_config

	# now relaunch safely
	relaunch_inside_kitty

	# continue remaining setup
	run_step "$INSTALL_DIR/scripts/bootnvim.sh"
	run_step "$INSTALL_DIR/scripts/linknvim.sh"
	run_step "$INSTALL_DIR/scripts/linkbin.sh"

	ok "Bootstrap complete"
	ok "Repo: $INSTALL_DIR"
}

main "$@"
