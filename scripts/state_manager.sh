#!/usr/bin/env bash

# - # - # - # - # - # - #
#  Variable Declaration #
# - # - # - # - # - # - #

# String variables
STATE_FILE="$HOME/.local/state/state_machine.json"
KITTY_THEME_FILE="${KITTY_THEME_FILE:-$HOME/.config/kitty/current-theme.conf}"

# Numeric variables
QUIET=0
NUMERIC=0
SILENT=0

# Array variables

BOOLEAN_KEYS=(
	".ui.git.show"
	".ui.hostname.show"
	".ui.time.show"
	".ui.dir.show"
	".ui.dir.shorten"
	".ui.arrow.status"
)

SIDE_KEYS=(
	".ui.hostname.side"
	".ui.time.side"
)

NUMERIC_KEYS=(
	".ui.dir.max_ratio"
)

ROLE_KEYS=(
	".theme.roles.hostname"
	".theme.roles.git"
	".theme.roles.dir"
	".theme.roles.time"
	".theme.roles.arrow"
	".theme.roles.success"
	".theme.roles.error"
	".theme.roles.warning"
)

MAX_PALETTE_INDEX=31
PALETTE_KEYS=()

# - # - # - #
# Functions #
# - # - # - #

# Log print functions
ok() {
	[[ "$QUIET" -eq 0 && "$SILENT" -eq 0 ]] || return 0
	tput setaf 51 >&2
	printf '[OK]' >&2
	tput sgr0 >&2
	printf ' %s' "$1" >&2
	if [ "$#" -gt 1 ]; then
		shift
		tput setaf 51 >&2
		printf ' %s\n' "$*" >&2
		tput sgr0 >&2
	else
		printf '\n' >&2
	fi
	return 0
}

err() {
	tput setaf 1 >&2
	printf '[ERROR]' >&2
	tput sgr0 >&2
	printf ' %s' "$1" >&2
	if [ "$#" -gt 1 ]; then
		shift
		tput setaf 1 >&2
		printf ' %s\n' "$*" >&2
		tput sgr0 >&2
	else
		printf '\n' >&2
	fi
	exit 1
}

# File creating functions

build_palette_keys() {
	local i
	PALETTE_KEYS=()
	for ((i=0; i<=MAX_PALETTE_INDEX; i++)); do
		PALETTE_KEYS+=(".palette.color$i")
	done
}

backup_state_file() {
	local backup_dir="$HOME/.local/tmp/state_manager_backups"
	local timestamp
	local backup_file

	timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
	backup_file="$backup_dir/state_machine_${timestamp}.json"

	mkdir -p "$backup_dir" || err "Failed to create backup directory" "$backup_dir"
	cp "$STATE_FILE" "$backup_file" || err "Failed to create backup file" "$backup_file"

	printf '%s\n' "$backup_file"
}

create_state_file() {
	local state_dir

	state_dir="$(dirname "$STATE_FILE")"
	mkdir -p "$state_dir"

	cat > "$STATE_FILE" <<'EOF'
{
	"ui": {
		"git": {
			"show": true
		},
		"dir": {
			"show": true,
			"shorten": true,
			"max_ratio": 40
		},
		"hostname": {
			"show": true,
			"side": "left"
		},
		"time": {
			"show": false,
			"side": "right"
		},
		"arrow": {
			"status": true
		}
	},
	"theme": {
		"roles": {
			"hostname": "color1",
			"git": "color1",
			"dir": "color1",
			"time": "color1",
			"arrow": "color1",
			"success": "color1",
			"error": "color1",
			"warning": "color1"
		}
	},
	"palette": {
		"color0": "#FFFFFF",
		"color1": "#FFFFFF",
		"color2": "#FFFFFF",
		"color3": "#FFFFFF",
		"color4": "#FFFFFF",
		"color5": "#FFFFFF",
		"color6": "#FFFFFF",
		"color7": "#FFFFFF",
		"color8": "#FFFFFF",
		"color9": "#FFFFFF",
		"color10": "#FFFFFF",
		"color11": "#FFFFFF",
		"color12": "#FFFFFF",
		"color13": "#FFFFFF",
		"color14": "#FFFFFF",
		"color15": "#FFFFFF",
		"color16": "#FFFFFF",
		"color17": "#FFFFFF",
		"color18": "#FFFFFF",
		"color19": "#FFFFFF",
		"color20": "#FFFFFF",
		"color21": "#FFFFFF",
		"color22": "#FFFFFF",
		"color23": "#FFFFFF",
		"color24": "#FFFFFF",
		"color25": "#FFFFFF",
		"color26": "#FFFFFF",
		"color27": "#FFFFFF",
		"color28": "#FFFFFF",
		"color29": "#FFFFFF",
		"color30": "#FFFFFF",
		"color31": "#FFFFFF"
	}
}
EOF

	ok "State machine created at" "$STATE_FILE"
}

# Helpers

validate_set_palette_value() {
	local value="$1"

	[[ "$value" =~ ^#[0-9A-Fa-f]{6}$ ]] || err "Invalid palette value (must be 6-digit hex):" "$value"
}

validate_set_boolean_value() {
	local value="$1"
	local ret=1

	if [[ "$value" == "true" || "$value" == "false" ]]; then
		ret=0
	fi
	
	if [[ "$ret" -eq 1 ]] && [[ "$value" == "0" || "$value" == "1" ]]; then
		ret=0
	fi
	[[ "$ret" -eq 0 ]] || err "Invalid boolean value (must be true/false):" "$value"
}

validate_set_side_value() {
	local value="$1"
	local ret=1

	if [[ "$value" == "left" || "$value" == "right" ]]; then
		ret=0
	fi
	
	if [[ "$ret" -eq 1 ]] && [[ "$value" == "0" || "$value" == "1" ]]; then
		ret=0
	fi
	[[ "$ret" -eq 0 ]] || err "Invalid positional value (must be left/right):" "$value"
}

validate_set_numeric_value() {
	local value="$1"

	[[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || err "Invalid numeric value:" "$value"
}

validate_set_role_value() {
	local key="$1"
	local index

	[[ "$key" =~ ^color([0-9]+)$ ]] || err "Invalid role value (must be a palette color):" "$value"
	index="${BASH_REMATCH[1]}"

	(( index >= 0 && index <= MAX_PALETTE_INDEX )) || err "Out of range role (must be color0 through color${MAX_PALETTE_INDEX}):" "$value"
}

key_in_list() {
	local candidate="$1"
	shift
	local key

	for key in "$@"; do
		[[ "$candidate" == "$key" ]] && return 0
	done

	return 1
}

is_allowed_set_key() {
	local candidate="$1"

	key_in_list "$candidate" "${BOOLEAN_KEYS[@]}" && return 0
	key_in_list "$candidate" "${SIDE_KEYS[@]}" && return 0
	key_in_list "$candidate" "${NUMERIC_KEYS[@]}" && return 0
	key_in_list "$candidate" "${ROLE_KEYS[@]}" && return 0
	key_in_list "$candidate" "${PALETTE_KEYS[@]}" && return 0

	return 1
}

is_allowed_toggle_key() {
	local candidate="$1"

	key_in_list "$candidate" "${BOOLEAN_KEYS[@]}" && return 0
	key_in_list "$candidate" "${SIDE_KEYS[@]}" && return 0

	return 1
}

# - # - # - # - # - #
# Getters & Setters #
# - # - # - # - # - #

get_json_value() {
	local key="$1"
	local value

	value="$(jq -r "${key}" "$STATE_FILE")" || err "jq failed while reading key" "$key"

	if [[ "$value" == "null" ]]; then
		err "Key not found in state file" "$key"
	fi

	if [[ "$NUMERIC" -eq 1 ]]; then
		if [[ "$value" == "true" || "$value" == "right" ]]; then
			value=1
		elif [[ "$value" == "false" || "$value" == "left" ]]; then
			value=0
		else
			err "Failed to simplify key's value to numerical representation:" "$key"
		fi
	fi

	printf '%s\n' "$value"
}

set_json_value() {
	local key="$1"
	local new_value="$2"
	local tmp_file
	local backup_path

	is_allowed_set_key "$key" || err "Refusing to set unknown key" "$key"

	if key_in_list "$key" "${PALETTE_KEYS[@]}"; then
		validate_set_palette_value "$new_value"

	elif key_in_list "$key" "${ROLE_KEYS[@]}"; then
		validate_set_role_value "$new_value"

	elif key_in_list "$key" "${BOOLEAN_KEYS[@]}"; then
		validate_set_boolean_value "$new_value"
		case "$new_value" in
			1) new_value="true" ;;
			0) new_value="false" ;;
		esac

	elif key_in_list "$key" "${SIDE_KEYS[@]}"; then
		validate_set_side_value "$new_value"
		case "$new_value" in
			1) new_value="right" ;;
			0) new_value="left" ;;
		esac

	elif key_in_list "$key" "${NUMERIC_KEYS[@]}"; then
		validate_set_numeric_value "$new_value"

	else
		err "No validator defined for key" "$key"
	fi

	tmp_file="$(mktemp)" || err "Failed to create temporary file"

	if key_in_list "$key" "${BOOLEAN_KEYS[@]}" || key_in_list "$key" "${NUMERIC_KEYS[@]}"; then
		jq --argjson value "$new_value" "${key} = \$value" "$STATE_FILE" > "$tmp_file" || {
			rm -f "$tmp_file"
			err "Failed to update key" "$key"
		}
	else
		jq --arg value "$new_value" "${key} = \$value" "$STATE_FILE" > "$tmp_file" || {
			rm -f "$tmp_file"
			err "Failed to update key" "$key"
		}
	fi

	jq empty "$tmp_file" > /dev/null 2>&1 || {
		rm -f "$tmp_file"
		err "Temporary file is not valid JSON"
	}

	jq -e "${key} != null" "$tmp_file" > /dev/null 2>&1 || {
		rm -f "$tmp_file"
		err "Updated key is missing or null after write" "$key"
	}

	backup_path="$(backup_state_file)" || {
		rm -f "$tmp_file"
		err "Failed to back up state file"
	}

	mv "$tmp_file" "$STATE_FILE" || {
		rm -f "$tmp_file"
		err "Failed to replace state file"
	}

	ok "Updated key" "$key" "Backup:" "$backup_path"
}

toggle_json_value() {
	local key="$1"
	local current_value
	local new_value
	local old_silent="$SILENT"

	is_allowed_set_key "$key" || err "Refusing to toggle unknown key" "$key"
	is_allowed_toggle_key "$key" || err "Refusing to toggle non-boolean key" "$key"

	current_value="$(jq -r "${key}" "$STATE_FILE")" || err "jq failed while reading key" "$key"
	if [[ "$current_value" == "null" ]]; then
		err "Key not found in state file" "$key"
	fi

	case "$current_value" in
		true)
			new_value="false"
			;;
		false)
			new_value="true"
			;;
		left)
			new_value="right"
			;;
		right)
			new_value="left"
			;;
		*)
			err "Cannot toggle non-boolean key" "$key"
			;;
	esac

	SILENT=1
	set_json_value "$key" "$new_value"
	SILENT="$old_silent"
	ok "Toggled key" "$key"
	ok "New value:" "$new_value"
}

set_theme_role() {
	local role="$1"
	local palette_name="$2"
	local role_key
	local tmp_file
	local backup_path

	role_key=".theme.roles.$role"
	key_in_list "$role_key" "${ROLE_KEYS[@]}" || err "Unknown theme role" "$role"

	is_valid_palette_name "$palette_name" || err "Invalid palette name" "$palette_name"

	tmp_file="$(mktemp)" || err "Failed to create temporary file"

	jq \
		--arg role "$role" \
		--arg palette_name "$palette_name" \
		'.theme.roles[$role] = $palette_name' \
		"$STATE_FILE" > "$tmp_file" || {
			rm -f "$tmp_file"
			err "Failed to set theme role"
		}

	backup_path="$(backup_state_file)" || {
		rm -f "$tmp_file"
		err "Failed to back up state file"
	}

	mv "$tmp_file" "$STATE_FILE" || {
		rm -f "$tmp_file"
		err "Failed to replace state file"
	}

	ok "Updated theme role. Backup:" "$backup_path"
}

set_theme_palette() {
	local error="$1"
	local success="$2"
	local warning="$3"
	local contrast1="$4"
	local contrast2="$5"
	local contrast3="$6"
	local blend1="$7"
	local blend2="$8"

	local tmp_file
	local backup_path

	tmp_file="$(mktemp)" || err "Failed to create temporary file"

	jq \
		--arg error "$error" \
		--arg success "$success" \
		--arg warning "$warning" \
		--arg contrast1 "$contrast1" \
		--arg contrast2 "$contrast2" \
		--arg contrast3 "$contrast3" \
		--arg blend1 "$blend1" \
		--arg blend2 "$blend2" \
		'
		.theme.palette.error = $error |
		.theme.palette.success = $success |
		.theme.palette.warning = $warning |
		.theme.palette.contrast1 = $contrast1 |
		.theme.palette.contrast2 = $contrast2 |
		.theme.palette.contrast3 = $contrast3 |
		.theme.palette.blend1 = $blend1 |
		.theme.palette.blend2 = $blend2 
		' \
		"$STATE_FILE" > "$tmp_file" || {
			rm -f "$tmp_file"
			err "Failed to update theme palette"
		}

	jq -e '
		.theme.palette.error != null and
		.theme.palette.success != null and
		.theme.palette.warning != null and
		.theme.palette.contrast1 != null and
		.theme.palette.contrast2 != null and
		.theme.palette.contrast3 != null and
		.theme.palette.blend1 != null and
		.theme.palette.blend2 != null
		' \
		"$tmp_file" > /dev/null 2>&1 || {
		rm -f "$tmp_file"
		err "Updated theme palette is incomplete"
	}

	jq empty "$tmp_file" > /dev/null 2>&1 || {
		rm -f "$tmp_file"
		err "Temporary file is not valid JSON"
	}
	
	backup_path="$(backup_state_file)" || {
		rm -f "$tmp_file"
		err "Failed to back up state file"
	}

	mv "$tmp_file" "$STATE_FILE" || {
		rm -f "$tmp_file"
		err "Failed to replace state file"
	}

	ok "Updated theme palette. Backup:" "$backup_path"
}

get_kitty_color() {
	local file="$1"
	local slot="$2"

	[[ -f "$file" ]] || return 1

	awk -v slot="$slot" '
		$1 == slot && NF >= 2 {
			print $2
			exit
		}
	' "$file"
}

resolve_theme_role() {
  local role="$1"
  local palette_key
  local color

  palette_key="$(jq -r --arg role "$role" '.theme.roles[$role]' "$STATE_FILE")" \
    || err "Failed to read theme role" "$role"

  [[ "$palette_key" != "null" ]] || err "Unknown theme color" "$role"

  color="$(jq -r --arg key "$palette_key" '.palette[$key]' "$STATE_FILE")" \
    || err "Failed to resolve palette key for color" "$role"

  [[ "$color" != "null" ]] || err "Palette key not found for role" "$role"

  printf '%s\n' "$color"
}

# - # - # - # - # - #
#  Boot  functions  #
# - # - # - # - # - #

reset_json() {
	if [[ -f "$STATE_FILE" ]]; then
		backup_state_file >/dev/null
	fi

	rm -f "$STATE_FILE" || err "Could not remove existing state file"

	create_state_file || err "Could not build state file"

	ok "Created state file at" "$STATE_FILE"
	exit 0
}

boot_colors_from_kitty() {
	local kitty_file="$KITTY_THEME_FILE"
	local color1 color2 color3 color5 color6 color7 color9 color10

	[[ -f "$kitty_file" ]] || err "Kitty theme file not found at" "$kitty_file"

	color1="$(get_kitty_color "$kitty_file" color1)"
	color2="$(get_kitty_color "$kitty_file" color2)"
	color3="$(get_kitty_color "$kitty_file" color3)"
	color5="$(get_kitty_color "$kitty_file" color5)"
	color6="$(get_kitty_color "$kitty_file" color6)"
	color7="$(get_kitty_color "$kitty_file" color7)"
	color9="$(get_kitty_color "$kitty_file" color9)"
	color10="$(get_kitty_color "$kitty_file" color10)"

	[[ -n "$color1" ]] || color1="#ff0000"
	[[ -n "$color2" ]] || color2="#00ff00"
	[[ -n "$color3" ]] || color3="#ffff00"
	[[ -n "$color5" ]] || color5="#ff00ff"
	[[ -n "$color6" ]] || color6="#00ffff"
	[[ -n "$color7" ]] || color7="#ffffff"
	[[ -n "$color9" ]] || color9="#ff5555"
	[[ -n "$color10" ]] || color10="#55ff55"

	set_theme_palette \
		"$color1" \
		"$color2" \
		"$color3" \
		"$color5" \
		"$color6" \
		"$color7" \
		"$color9" \
		"$color10"

	ok "Bootstrapped theme colors from kitty's theme file" "$kitty_file"
	exit 0
}

# - # - # - #
# Main flow #
# - # - # - #

usage() {
	cat <<EOF
Usage:
	$0 [-flags]
Gets, sets, toggles and bootstraps various values on a
state_machine.json file that the terminal will use for
consistent behavior between executions.

Options:
	--get,			-g	Returns current value of a json key
	--set,			-s	Sets a key to a new given value
	--toggle,		-t	Toggles a boolean key between true/false
						or a positional key between left/right
	--bootstrap,		-b	Enforces json file existence while
					setting it to default values
	--boot-colors			Searches ${KITTY_THEME_FILE}
					saving values seen there for terminal
					theme values
	--numeric,		-n	Simplifies boolean and positional keys
					0 for 'false' and 'left' values,
					1 for 'true' and 'right' values
	--quiet,		-q	Suppress regular output
	--locate,		-l	Prints path to state_machine.json file
	--help,			-h	Show this help

Examples:
	$0 -g .ui.show_git
	$0 -s .palette.color21 '#ff00ff'
	$0 -t .ui.hostname.show
	$0 --boot-colors
EOF
	exit 0
}

parse_args() {
	local unique=0
	local multi=0
	local action=""
	local key=""
	local new_value=""
	local role=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-g|--get)
				[[ -n "${2:-}" ]] || err "Missing key for get operation"
				action="get"
				key="$2"
				multi=1
				shift 2
				;;
			-s|--set)
				[[ -n "${2:-}" ]] || err "Missing key for set operation"
				[[ -n "${3:-}" ]] || err "Missing value for set operation"
				action="set"
				key="$2"
				new_value="$3"
				multi=1
				shift 3
				;;
			-n|--numeric)
				NUMERIC=1
				shift
				;;
			-l|--locate)
				ok "State Machine located at" "$STATE_FILE"
				exit 0
				;;
			-q|--quiet)
				QUIET=1
				shift
				;;
			-t|--toggle)
				[[ -n "${2:-}" ]] || err "Missing key for toggle operation"
				action="toggle"
				key="$2"
				multi=1
				shift 2
				;;
			--boot-colors)
				[[ "$unique" -eq 0 ]] || err "Can't --bootstrap and --boot-colors on the same run"
				unique=1
				action="bcolors"
				shift
				;;
			-b|--boot|--bootstrap|--rebuild|--reset)
				[[ "$unique" -eq 0 ]] || err "Can't --boot-colors and --bootstrap on the same run"
				unique=1
				action="boot"
				shift
				;;
			--resolve-role)
				[[ -n "${2:-}" ]] || err "Missing role for resolve-role operation"
				action="resolve"
				role="$2"
				multi=1
				shift 2
				;;
			""|-h|--help)
				usage
				;;
			*)
				err "Unknown flag" "$1"
				;;
		esac
	done

	if [[ "$unique" -eq 1 && "$multi" -eq 1 ]]; then
		err "Can't mix boot flags like --bootstrap with action flags like --toggle"
	fi

	case "$action" in
		get)
			get_json_value "$key"
			;;
		set)
			set_json_value "$key" "$new_value"
			;;
		toggle)
			toggle_json_value "$key"
			;;
		resolve)
			resolve_theme_role "$role"
			;;
		boot)
			reset_json
			;;
		bcolors)
			boot_colors_from_kitty
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
	if [[ "$#" -eq 0 ]]; then
		usage
	fi

	if [[ -d "$STATE_FILE" ]]; then
		err "State file exists as a dir at" "$STATE_FILE"
	fi

	parse_args "$@"
}

build_palette_keys
main "$@"
