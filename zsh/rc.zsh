ZSH_DIR="${${(%):-%N}:A:h}"

export PATH="$HOME/.local/bin:$PATH"

[ -f "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh"
