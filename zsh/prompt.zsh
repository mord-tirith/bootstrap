setopt PROMPT_SUBST

export SHOW_HOST_IN_PROMPT="${SHOW_HOST_IN_PROMPT:-0}"
export PROMPT_LEFT_KEEP="${PROMPT_LEFT_KEEP:-1}"
export PROMPT_RIGHT_KEEP="${PROMPT_RIGHT_KEEP:-2}"
export PROMPT_MAX_RATIO="${PROMPT_MAX_RATIO:-60}"   # max % of terminal width prompt may occupy

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
		prefix=""
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

render_path_mode() {
	local mode="$1"
	local path_color="%F{blue}"
	local short_color="%F{green}"
	local reset="%f"

	local raw
	local prefix
	local left
	local middle
	local right

	local out=""

	raw="$(build_path_segments)"
	prefix="${raw%%|*}"
	raw="${raw#*|}"
	left="${raw%%|*}"
	raw="${raw#*|}"
	middle="${raw%%|*}"
	right="${raw#*|}"

	case "$mode" in
		full|nohost)
			if [ "$prefix" = "~" ]; then
				out="${path_color}~"
			else
				out="${path_color}/"
			fi

			if [ -n "$left" ]; then
				if [ "$prefix" = "~" ]; then
					out="${out}/${left}"
				else
					out="${out}${left}"
				fi
			fi

			if [ -n "$middle" ]; then
				out="${out}/${short_color}${middle}${path_color}"
			fi

			if [ -n "$right" ]; then
				out="${out}/${right}"
			fi

			out="${out}${reset}"
			printf '%s' "$out"
			;;

		noleft)
			out="${path_color}..."
			if [ -n "$middle" ]; then
				out="${out}/${short_color}${middle}${path_color}"
			fi
			if [ -n "$right" ]; then
				out="${out}/${right}"
			fi
			out="${out}${reset}"
			printf '%s' "$out"
			;;

		nomiddle)
			out="${path_color}..."
			if [ -n "$right" ]; then
				out="${out}/${right}"
			fi
			out="${out}${reset}"
			printf '%s' "$out"
			;;

		short)
			local last=""
			if [ -n "$right" ]; then
				last="${right##*/}"
			elif [ -n "$left" ]; then
				last="${left##*/}"
			fi

			out="${path_color}..."
			if [ -n "$last" ]; then
				out="${out}/${last}"
			fi
			out="${out}${reset}"
			printf '%s' "$out"
			;;

		arrow)
			printf ''
			;;
	esac
}

strip_prompt_colors() {
	local text="$1"
	printf '%s' "$text" | sed -E 's/%([BFKfubk]|F\{[^}]+\}|K\{[^}]+\})//g'
}

prompt_limit() {
	local cols ratio limit
	cols="$(tput cols 2>/dev/null || printf '80')"
	ratio="${PROMPT_MAX_RATIO:-40}"
	limit=$(( cols * ratio / 100 ))

	if [ "$limit" -lt 12 ]; then
		limit=12
	fi

	printf '%d' "$limit"
}

fits_prompt() {
	local candidate="$1"
	local stripped
	local limit

	stripped="$(strip_prompt_colors "$candidate")"
	limit="$(prompt_limit)"

	[ "${#stripped}" -le "$limit" ]
}

build_prompt() {
	local last_status=$?
	local arrow_color
	local host_color="%F{cyan}"
	local reset="%f"

	local host_part=""
	local arrow_part
	local path_part
	local candidate

	if [ "$last_status" -eq 0 ]; then
		arrow_color="%F{green}"
	else
		arrow_color="%F{red}"
	fi

	arrow_part=" ${arrow_color}->${reset} "

	if [ "${SHOW_HOST_IN_PROMPT:-0}" -eq 1 ]; then
		host_part="${host_color}[%m]${reset} "
	fi

	path_part="$(render_path_mode full)"
	candidate="${host_part}${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode noleft)"
	candidate="${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode nomiddle)"
	candidate="${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode short)"
	candidate="${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	PROMPT="${arrow_color}->${reset} "
}

precmd() {
	build_prompt
}
