setopt prompt_subst

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
	local left=""
	local right=""

	left+="$(build_time_part 0)"
	right+="$(build_time_part 1)"

	left+="$(build_hostname_part 0)"
	right+="$(build_hostname_part 1)"

	left+="$(build_status_arrow "$last_status")"
	PROMPT="$left"
	RPROMPT="$right"
}

precmd() {
	local last_status="$?"
	build_prompt "$last_status"
}
