#!/usr/bin/env bash
set -euo pipefail

VERBOSE=0
QUIET=0
FORCE=0
PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
OPT_DIR="$PREFIX/opt"
TMP_DIR="$PREFIX/tmp"
NVIM_INSTALL_DIR="$OPT_DIR/nvim"
NVIM_LINK="$BIN_DIR/nvim"

log() {
	[ "$QUIET" -eq 1 ] && return 0
	[ "$VERBOSE" -eq 1 ] && printf '\033[1;34m[INFO]\033[0m %s\n' "$*";
	return 0
}

ok()   {
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;32m[ OK ]\033[0m %s\n' "$*";
	return 0
}

warn() { 
	[ "$QUIET" -eq 1 ] && return 0
	[ "$VERBOSE" -eq 1 ] && printf '\033[1;33m[WARN]\033[0m %s\n' "$*";
	return 0
}
err()  { 
	[ "$QUIET" -eq 1 ] && return 0
	printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2;
	return 0
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Missing required command: $1"
    exit 1
  }
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)
      err "Unsupported architecture: $arch"
      exit 1
      ;;
  esac
}

latest_tarball_url() {
  local arch="$1"
  case "$arch" in
    x86_64) echo "https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-x86_64.tar.gz" ;;
    arm64)  echo "https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-arm64.tar.gz" ;;
    *)
      err "No tarball URL for architecture: $arch"
      exit 1
      ;;
  esac
}

installed_version() {
  if [ -x "$NVIM_LINK" ]; then
    "$NVIM_LINK" --version 2>/dev/null | awk 'NR==1 {print $2}' | sed 's/^v//'
    return 0
  fi

  if command -v nvim >/dev/null 2>&1; then
    command -v nvim >/dev/null 2>&1 || return 1
    nvim --version 2>/dev/null | awk 'NR==1 {print $2}' | sed 's/^v//'
    return 0
  fi

  return 1
}

latest_version() {
  curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" \
    | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' \
    | head -n1
}

version_ge() {
  # returns 0 if $1 >= $2
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

download_and_install() {
  local arch url workdir tarball extracted_dir
  arch="$(detect_arch)"
  url="$(latest_tarball_url "$arch")"

  mkdir -p "$BIN_DIR" "$OPT_DIR" "$TMP_DIR"
  workdir="$(mktemp -d "$TMP_DIR/nvim-install.XXXXXX")"
  trap "rm -rf -- '$workdir'" EXIT

  tarball="$workdir/nvim.tar.gz"

  log "Downloading Neovim for $arch..."
  if [ "$VERBOSE" -eq 1 ]; then
	  curl -fL "$url" -o "$tarball"
  else
	  curl -fsSL "$url" -o "$tarball"
  fi

  log "Extracting release..."
  if [ "$VERBOSE" -eq 1 ]; then
	  tar -xzf "$tarball" -C "$workdir"
  else
	  tar -xzf "$tarball" -C "$workdir" >/dev/null 2>&1
  fi

  extracted_dir="$(find "$workdir" -mindepth 1 -maxdepth 1 -type d -name 'nvim-linux-*' | head -n1)"
  if [ -z "${extracted_dir:-}" ]; then
    err "Could not find extracted Neovim directory."
    exit 1
  fi

  log "Replacing previous installation..."
  rm -rf "$NVIM_INSTALL_DIR"
  mkdir -p "$OPT_DIR"
  mv "$extracted_dir" "$NVIM_INSTALL_DIR"

  ln -sfn "$NVIM_INSTALL_DIR/bin/nvim" "$NVIM_LINK"
  chmod +x "$NVIM_INSTALL_DIR/bin/nvim"

  ok "Installed Neovim to $NVIM_INSTALL_DIR"
  ok "Linked $NVIM_LINK -> $NVIM_INSTALL_DIR/bin/nvim"
}

print_summary() {
  local v path
  path="${NVIM_LINK}"
  if [ -x "$path" ]; then
    v="$("$path" --version | awk 'NR==1 {print $2}')"
    ok "Current Neovim: $v"
    ok "Executable: $path"
  else
    warn "Neovim link not found after install."
  fi
}

main() {
  need_cmd curl
  need_cmd tar
  need_cmd find
  need_cmd sed
  need_cmd awk
  need_cmd sort
  need_cmd uname

  for arg in "$@"; do
	  case "$arg" in
		  --verbose|-v) VERBOSE=1 ;;
		  --quiet|-q) QUIET=1 ;;
		  --force|-f) FORCE=1;;
	  esac
  done
  mkdir -p "$BIN_DIR" "$OPT_DIR" "$TMP_DIR"

  local current latest force
  force="$FORCE"

  latest="$(latest_version)"
  if [ -z "$latest" ]; then
    err "Could not determine latest Neovim version."
    exit 1
  fi

  if current="$(installed_version 2>/dev/null)"; then
    log "Installed Neovim version: $current"
  else
    current=""
    log "No existing Neovim installation detected in user space."
  fi

  log "Latest stable Neovim version: $latest"

  if [ "$force" -eq 1 ]; then
    warn "Force flag detected; reinstalling Neovim."
    download_and_install
    print_summary
    exit 0
  fi

  if [ -n "$current" ] && [ "$current" = "$latest" ]; then
    ok "Neovim is already up to date."
    print_summary
    exit 0
  fi

  if [ -n "$current" ]; then
    log "Updating Neovim from $current to $latest..."
  else
    log "Installing Neovim $latest..."
  fi

  download_and_install
  print_summary
}

main "$@"
