# Bootstrap:
alias bootstrap='~/.dotfiles/scripts/bootstrap.sh'

# Historic settings:

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt share_history

# Prep .local for personal apps
export PATH="$HOME/.local/bin:$PATH"

# Enable simple coloring
autoload -U colors && colors

alias ls='ls --color=auto'

# Github aliases
alias gst='git status'
alias gc='git commit -m'
alias ga='git add'
alias gr='git rm'
alias gp='git push'

# Minimal everyday aliases
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias v='nvim'

# Simple prompt
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '

# Enable tab completion
autoload -Uz compinit
compinit

# Load and configure history search widgets
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# Bind multiple possible arrow key sequences
bindkey "^[[A" history-beginning-search-backward-end  # Standard
bindkey "^[OA" history-beginning-search-backward-end  # Alternative
bindkey "^[[B" history-beginning-search-forward-end   # Standard
bindkey "^[OB" history-beginning-search-forward-end   # Alternative

# Optional: display exit status of last command if non-zero
precmd() {
       	if [ $? -ne 0 ]; then
		PROMPT='%F{red}%n@%m%f:%F{blue}%~%f$ '
	else
		PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
	fi
}

# C++ norme compiler
alias c++='c++ -Wall -Wextra -Werror -std=c++98'

# Automatic binary namer
cco () {
	local	first_c

	for arg in "$@"; do
		if [[ "$arg" == *.c ]]; then
			first_c="$arg"
			break
		fi
	done
	if [[ -z "$first_c" ]]; then
		echo "cco: no .c file provided" >&2
		return 1
	fi
	cc "$@" -o "${first_c%.c}" && echo "→ output: ${first_c%.c}"
}

# The logger

log_all() {
    local tmpfile=/tmp/log_all_log_file.txt

    # Ensure log file exists
        if [[ ! -f $tmpfile ]]; then
		touch "$tmpfile"
	else
		echo "" > "$tmpfile"
	fi

    # Parse arguments
    local include_hidden=0
    local exts=()

    # Known extension families
    local -A ext_map=(
        [c]="c h"
        [cpp]="cpp hpp"
	[lua]="lua"
    )

    # Always ignored directories
    local ignore_dirs=(.git __pycache__ node_modules)

    for arg in "$@"; do
        if [[ "$arg" == "all" ]]; then
            include_hidden=1
        else
            if [[ -n "${ext_map[$arg]}" ]]; then
                exts+=(${(s: :)ext_map[$arg]})
            else
                exts+=("$arg")
            fi
        fi
    done

    # Default extensions if none specified
    if [[ ${#exts[@]} -eq 0 ]]; then
        exts=(c h cpp hpp py sh lua)
    fi

    # Build find_args string for extensions
    local find_args=()
    local first=1
    for ext in "${exts[@]}"; do
        [[ $first -eq 0 ]] && find_args+=(-o)
	find_args+=(-name "*.${ext}")
        first=0
    done

    # Hidden files exclusion
    local hidden_args=()
    if [[ $include_hidden -eq 0 ]]; then
        hidden_args=(-not -name '.*')
    fi

    # Ignore directories
    local ignore_args=()
    for dir in "${ignore_dirs[@]}"; do
        ignore_args+=(-not -path "*/$dir/*")
    done

    echo "Searching for files..."
    # Collect files
    local files=()
    while IFS= read -r file; do
        files+=("$file")
done < <(noglob find -L . -type f \( "${find_args[@]}" \) "${hidden_args[@]}" "${ignore_args[@]}" | sort)

    echo "Found ${#files[@]} files"

    # Write to log file
    for file in "${files[@]}"; do
        echo "==== START OF ${file#./} ====" >> "$tmpfile"
        cat "$file" >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "==== END OF ${file#./} ====" >> "$tmpfile"
        echo "" >> "$tmpfile"
    done

    open "$tmpfile"
}

locate() {
  grep -RIn --color=auto "$1" .
}
