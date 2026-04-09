setopt PROMPT_SUBST

export SHOW_HOST_IN_PROMPT="${SHOW_HOST_IN_PROMPT:-0}"
export PROMPT_LEFT_KEEP="${PROMPT_LEFT_KEEP:-1}"
export PROMPT_RIGHT_KEEP="${PROMPT_RIGHT_KEEP:-2}"

toggle_hostname() {
	if [ "${SHOW_HOST_IN_PROMPT:-0}" -eq 1 ]; then
		export SHOW_HOST_IN_PROMPT=0
		echo "Hostname hidden"
	else
		export SHOW_HOST_IN_PROMPT=1
		echo "Hostname shown"
	fi
}

join_path_parts() {
	local result=""
	local part

	for part in "$@"; do
		if [ -z "$result" ]; then
			result="$part"
		else
			result="$result/$part"
		fi
	done

	printf '%s' "$result"
}

build_path_segments() {
	local cwd="$PWD"
	local home="$HOME"
	local prefix
	local rel
	local -a parts left_parts right_parts
	local total hidden_count
	local left_keep="${PROMPT_LEFT_KEEP:-1}"
	local right_keep="${PROMPT_RIGHT_KEEP:-2}"
	local i

	if [ "$cwd" = "$home" ]; then
		printf '~|||'
		return
	fi

	if [ "$cwd" = "/" ]; then
		printf '/|||'
		return
	fi

	if [[ "$cwd" == "$home/"* ]]; then
		prefix="~"
		rel="${cwd#$home/}"
	else
		prefix="/"
		rel="${cwd#/}"
	fi

	parts=("${(@s:/:)rel}")
	total=${#parts[@]}

	if [ "$total" -le $(( left_keep + right_keep )) ]; then
		printf '%s|%s||' "$prefix" "$rel"
		return
	fi

	left_parts=()
	right_parts=()

	i=1
	while [ "$i" -le "$left_keep" ]; do
		left_parts+=("${parts[$i]}")
		(( i++ ))
	done

	i=$(( total - right_keep + 1 ))
	while [ "$i" -le "$total" ]; do
		right_parts+=("${parts[$i]}")
		(( i++ ))
	done

	hidden_count=$(( total - left_keep - right_keep ))

	printf '%s|%s|(...%d...)|%s' \
		"$prefix" \
		"$(join_path_parts "${left_parts[@]}")" \
		"$hidden_count" \
		"$(join_path_parts "${right_parts[@]}")"
}

build_prompt_path() {
	local path_color="%F{blue}"
	local short_color="%F{green}"
	local reset="%f"

	local raw
	local prefix
	local left
	local middle
	local right

	raw="$(build_path_segments)"
	prefix="${raw%%|*}"
	raw="${raw#*|}"
	left="${raw%%|*}"
	raw="${raw#*|}"
	middle="${raw%%|*}"
	right="${raw#*|}"

	if [ -n "$left" ] && [ -n "$middle" ] && [ -n "$right" ]; then
		printf '%s%s/%s/%s%s/%s%s/%s%s' \
			"$path_color" "$prefix" \
			"$left" \
			"$short_color" "$middle" "$reset" \
			"$path_color" "$right" "$reset"
	elif [ -n "$left" ]; then
		printf '%s%s/%s%s' "$path_color" "$prefix" "$left" "$reset"
	else
		printf '%s%s%s' "$path_color" "$prefix" "$reset"
	fi
}

build_prompt() {
	local last_status=$?
	local arrow_color
	local host_color="%F{cyan}"
	local reset="%f"
	local path_part host_part=""

	if [ "$last_status" -eq 0 ]; then
		arrow_color="%F{green}"
	else
		arrow_color="%F{red}"
	fi

	path_part="$(build_prompt_path)"

	if [ "${SHOW_HOST_IN_PROMPT:-0}" -eq 1 ]; then
		host_part="${host_color}[%m]${reset} "
	fi

	PROMPT="${host_part}${path_part} ${arrow_color}->${reset} "
}

precmd() {
	build_prompt
}
