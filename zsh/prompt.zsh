setopt prompt_subst

prompt_visible_length() {
	local raw="$1"
	local expanded stripped

	expanded="$(print -P -- "$raw")"
	stripped="$(printf '%s' "$expanded" | sed -E $'s/\x1b\\[[0-9;]*[[:alpha:]]//g')"

	printf '%d' "${#stripped}"
}

prompt_budget() {
	local cols="$COLUMNS"
	local ratio="${P_DIR_MAX_RATIO:-40}"
	local budget

	(( ratio < 10 )) && ratio=10
	(( ratio > 95 )) && ratio=95

	budget=$(( cols * ratio / 100 ))
	(( budget < 20 )) && budget=20

	printf '%d' "$budget"
}

pick_dir_size() {
	local hostname_left="$1"
	local time_left="$2"
	local arrow="$3"
	local right_prompt="$4"

	local budget candidate total_len right_len

	budget="$(prompt_budget)"
	right_len="$(prompt_visible_length "$right_prompt")"

	for mode in full medium short tiny; do
		candidate="${hostname_left}$(build_dir_part "$mode")${time_left}${arrow}"
		total_len=$(( $(prompt_visible_length "$candidate") + right_len ))

		if (( total_len <= budget )); then
			printf '%s' "$mode"
			return
		fi
	done
	
	printf '%s' "tiny"
}

build_git_part() {
	[[ "$P_SHOW_GIT" -eq 1 ]] || return

	local branch

	branch="$(
		command git symbolic-ref --quiet --short HEAD 2>/dev/null ||
		command git describe --tags --exact-match 2>/dev/null ||
		command git rev-parse --short HEAD 2>/dev/null
	)" || return

	printf '%s[%s]%s' "$P_BLEND1" "$branch" "$P_RESET"
}

build_time_part()
{
	local side="$1"

	[[ "$side" -eq "$P_TIME_POS" && "$P_SHOW_TIME" -eq 1 ]] || return

	if [[ "$side" -eq 1 ]]; then
		printf '%s<%%*>%s' "$P_HILIGHT1" "$P_RESET"
	else
		printf '%s[%%T]%s' "$P_HILIGHT1" "$P_RESET"
	fi
}

build_hostname_part() {
	local side="$1"

	[[ "$side" -eq "$P_HOSTNAME_POS" ]] || return

	if [[ "$P_SHOW_HOSTNAME" -eq 1 ]]; then
		printf '%s[%%m]%s' "$P_WARNING" "$P_RESET"
	fi
}

build_dir_part() {
	local mode="$1"

	[[ "$P_SHOW_DIR" -eq 1 ]] || return

	case "$mode" in
		full)
			printf '%s%%~%s' "$P_HILIGHT2" "$P_RESET"
			;;
		medium)
			printf '%s%%2~%s' "$P_HILIGHT2" "$P_RESET"
			;;
		short)
			printf '%s%%1~%s' "$P_HILIGHT2" "$P_RESET"
			;;
		tiny)
			printf '%s%%c%s' "$P_HILIGHT2" "$P_RESET"
			;;
	esac
}

build_status_arrow() {
	local last_status="$1"
	local arrow_color

	if [[ "$last_status" -eq 0 ]]; then
		arrow_color="$P_SUCCESS"
	else
		arrow_color="$P_ERROR"
	fi

	printf '%s->%s ' "$arrow_color" "$P_RESET"
}

build_prompt() {
	local last_status="$1"

	local hostname_prompt hostname_rprompt
	local time_prompt time_rprompt
	local git_prompt
	local arrow_part
	local dir_part

	hostname_prompt="$(build_hostname_part 0)"
	hostname_rprompt="$(build_hostname_part 1)"

	time_prompt="$(build_time_part 0)"
	time_rprompt="$(build_time_part 1)"

	git_prompt="$(build_git_part)"

	arrow_part="$(build_status_arrow "$last_status")"

	dir_part="$(build_dir_part "$P_DIR_MODE")"

	PROMPT="${hostname_prompt}${git_prompt}${dir_part}${time_prompt}${arrow_part}"
	RPROMPT="${hostname_rprompt}${time_rprompt}"
}

update_prompt_layout() {
	local hostname_left hostname_right
	local time_left time_right
	local arrow_part
	local right_prompt

	hostname_left="$(build_hostname_part 0)"
	hostname_right="$(build_hostname_part 1)"

	time_left="$(build_time_part 0)"
	time_right="$(build_time_part 1)"

	right_prompt="${hostname_right}${time_right}"

	arrow_part="$(build_status_arrow 0)"

	if [[ "$P_DIR_SHORTEN_ACTIVE" -eq 1 ]]; then
		P_DIR_MODE="$(pick_dir_size "$hostname_left" "$time_left" "$arrow_part" "$right_prompt")"
	else
		P_DIR_MODE="full"
	fi		
}

precmd() {
	local last_status="$?"
	build_prompt "$last_status"
}

chpwd() {
	update_prompt_layout
}

TRAPWINCH() {
	update_prompt_layout
	if zle; then
		zle reset-prompt
	fi
}

update_prompt_layout
