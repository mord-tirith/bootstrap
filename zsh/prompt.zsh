setopt PROMPT_SUBST

export SHOW_HOST_IN_PROMPT="${SHOW_HOST_IN_PROMPT:-0}"
export SHOW_GIT_IN_PROMPT="${SHOW_GIT_IN_PROMPT:-1}"
export PROMPT_LEFT_KEEP="${PROMPT_LEFT_KEEP:-1}"
export PROMPT_RIGHT_KEEP="${PROMPT_RIGHT_KEEP:-2}"
export PROMPT_MAX_RATIO="${PROMPT_MAX_RATIO:-70}"   # max % of terminal width prompt may occupy
export GIT_PROMPT_MODE="${GIT_PROMPT_MODE:-1}"

toggle_hostname() {
	if [ "${SHOW_HOST_IN_PROMPT:-0}" -eq 1 ]; then
		export SHOW_HOST_IN_PROMPT=0
		echo "Hostname hidden"
	else
		export SHOW_HOST_IN_PROMPT=1
		echo "Hostname shown"
	fi
}

toggle_git() {
	if [ "${SHOW_GIT_IN_PROMPT:-0}" -eq 1 ]; then
		export SHOW_GIT_IN_PROMPT=0
		echo "Git info hidden"
	else
		export SHOW_GIT_IN_PROMPT=1
		echo "Git info shown"
	fi
}

detail_git() {
	local mode=""
	case "${GIT_PROMPT_MODE:-1}" in
		0)
			mode="branch"
			export GIT_PROMPT_MODE=1
			;;
		1)
			mode="repository"
			export GIT_PROMPT_MODE=2
			;;
		2)
			mode="repository + branch"
			export GIT_PROMPT_MODE=3
			;;
		*)
			mode="git only"
			export GIT_PROMPT_MODE=0
			;;
	esac
	echo "Git prompt mode: $mode"
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

render_git_part() {
	[ "${SHOW_GIT_IN_PROMPT:-0}" -eq 1 ] || return

	command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

	local branch
	local repo
	local top_level
	local label
	local title
	local status_output
	local line
	local git_color="%F{green}"
	local reset="%f"

	local has_unstaged=0
	local has_staged=0
	local has_untracked=0
	local has_unmerged=0
	local ahead=0
	local mode="${GIT_PROMPT_MODE:-1}"

	branch="$(command git symbolic-ref --quiet --short HEAD 2>/dev/null \
		|| command git describe --tags --exact-match 2>/dev/null \
		|| command git rev-parse --short HEAD 2>/dev/null)" || return

	top_level="$(command git rev-parse --show-toplevel 2>/dev/null)" || return
	repo="${top_level:t}"

	status_output="$(command git status --porcelain=v2 --branch 2>/dev/null)" || return

	while IFS= read -r line; do
		case "$line" in
			'# branch.ab '*)
				local ab
				ab="${line#\# branch.ab }"
				ahead="${ab%% *}"
				ahead="${ahead#+}"
				;;

			'? '*)
				has_untracked=1
				;;

			'u '*)
				has_unmerged=1
				;;

			'1 '*|'2 '*)
				local xy x y
				xy="${line[3,4]}"
				x="${xy[1,1]}"
				y="${xy[2,2]}"

				if [ "$x" != "." ]; then
					has_staged=1
				fi

				if [ "$y" != "." ]; then
					has_unstaged=1
				fi
				;;
		esac
	done <<< "$status_output"

	if [ "$has_untracked" -eq 1 ] || [ "$has_unstaged" -eq 1 ] || [ "$has_unmerged" -eq 1 ]; then
		git_color="%F{red}"
	elif [ "$has_staged" -eq 1 ]; then
		git_color="%F{yellow}"
	elif [ "$ahead" -gt 0 ]; then
		git_color="%F{blue}"
	else
		git_color="%F{green}"
	fi

	case "$mode" in
		0)
			label="git"
			;;
		1)
			if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
				label="$branch"
			else
				label="b: $branch"
			fi
			;;
		2)
			label="$repo"
			;;
		3)
			label="$repo: $branch"
			;;
		*)
			if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
				label="$branch"
			else
				label="b: $branch"
			fi
			;;
	esac

	printf '%s[%s]%s ' "$git_color" "$label" "$reset"
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

	local git_part=""
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
	
	git_part="$(render_git_part)"
	path_part="$(render_path_mode full)"
	candidate="${git_part}${host_part}${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode noleft)"
	candidate="${git_part}${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode nomiddle)"
	candidate="${git_part}${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	path_part="$(render_path_mode short)"
	candidate="${git_part}${path_part}${arrow_part}"
	if fits_prompt "$candidate"; then
		PROMPT="$candidate"
		return
	fi

	PROMPT="${git_part}${arrow_color}->${reset} "
}

precmd() {
	build_prompt
}
