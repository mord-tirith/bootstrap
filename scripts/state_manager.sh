#!/usr/bin/env bash

STATE_FILE="$HOME/.local/state/state_machine.json"
NUMERIC=0


ok() {
	tput setaf 51
	printf '[OK]'
	tput sgr0
	printf ' %s' "$1"
	if [ "$#" -gt 1 ]; then
		shift
		tput setaf 51
		printf ' %s\n' "$*"
		tput sgr0
	else
		printf '\n'
	fi

}

err() {
	tput setaf 1
	printf '[ERROR]'
	tput sgr0
	printf ' %s' "$1"
	if [ "$#" -gt 1 ]; then
		shift
		tput setaf 1
		printf ' %s\n' "$*"
		tput sgr0
	else
		printf '\n'
	fi
	exit 1
}

create_state_file() {
	local state_dir

	state_dir="$(dirname "$STATE_FILE")"

	mkdir -p "$state_dir"

	cat > "$STATE_FILE" << 'EOF'
	{
		"ui": {
			"show_git": true,
			"show_host": false
		},
		"theme": {
			"green": "#00ff00",
			"red": "#ff0000"
		}
	}
EOF

	ok "State machine created at" "$STATE_FILE"
}

get_json_value() {
	local key="$1"
	local value

	value="$(jq -r ".${key}" "$STATE_FILE")" || err "jq failed while reading key" "$key"
	if [[ "$value" == "null" ]]; then
		err "Key not found in state file" "$key"
	fi

	if [ "$NUMERIC" -eq 1 ]; then
		if [[ "$value" == "true" ]]; then
			value=1
		elif [[ "$value" == "false" ]]; then
			value=0
		else
			err "failed to simplify key's value to numerical representation:" "$key"
		fi
	fi

	printf '%s\n' "$value"
}

parse_args() {
	local action=""
	local key=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-g|--get)
				[[ -n "${2:-}" ]] || err "Missing key for get operation"
				action="get"
				key="$2"
				shift 2
				;;
			-n|--numeric)
				NUMERIC=1
				shift
				;;
			-l|--locate)
				ok "State Machine located at" "$STATE_FILE"
				exit 0
				;;
			"")
				shift
				;;
			*)
				err "Unknown flag" "$1";
				;;
		esac
	done

	case "$action" in
		get)
			get_json_value "$key"
			;;
		"")
			err "No action specified"
			;;
		*)
			err "Unknown action state" "$action"
			;;
	esac
}

main() {
	if [[ -d "$STATE_FILE" ]]; then
		err "State file exists as dir at" "$STATE_FILE"
	elif [[ ! -f "$STATE_FILE" ]]; then
		create_state_file
	fi

	parse_args "$@"
}

main "$@"
