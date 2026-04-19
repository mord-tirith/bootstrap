ZSH_DIR="${${(%):-%N}:A:h}"

export PATH="$HOME/.local/bin:$PATH"

[ -f "$ZSH_DIR/aliases.zsh" ] && source "$ZSH_DIR/aliases.zsh"
[ -f "$ZSH_DIR/history.zsh" ] && source "$ZSH_DIR/history.zsh"
[ -f "$ZSH_DIR/prompt_state.zsh" ] && source "$ZSH_DIR/prompt_state.zsh"
[ -f "$ZSH_DIR/prompt.zsh" ] && source "$ZSH_DIR/prompt.zsh"
[ -f "$ZSH_DIR/functions.zsh" ] && source "$ZSH_DIR/functions.zsh"


