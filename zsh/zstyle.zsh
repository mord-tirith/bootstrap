autoload -Uz compinit
compinit
zmodload zsh/complist

zstyle ':completion:*' menu select=1

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'  'l:|=* r:|=*'

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
