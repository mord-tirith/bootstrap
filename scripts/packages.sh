#!/usr/bin/env bash
set -euo pipefail



SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CURLER="$SCRIPT_DIR"
CURLER+="/curler.sh"

"$CURLER" https://gitlab.com/OldManProgrammer/unix-tree/-/archive/2.3.2/unix-tree-2.3.2.tar.bz2 tree -f

"$CURLER" https://github.com/sharkdp/fd/releases/download/v10.4.2/fd-v10.4.2-x86_64-unknown-linux-gnu.tar.gz fd -f

"$CURLER" https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz bat -f 

"$CURLER" https://github.com/junegunn/fzf/releases/download/v0.71.0/fzf-0.71.0-linux_amd64.tar.gz fzf -f
