ZSH_DIR="${${(%):-%N}:A:h}"

export PATH="$PATH:$HOME/.local/bin"

[ -f "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh"
