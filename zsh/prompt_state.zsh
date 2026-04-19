PROMPT_STATE_MANAGER="$HOME/.dotfiles/scripts/state_manager.sh"

load_prompt_env() {
	local sm="$PROMPT_STATE_MANAGER"
	local success_color error_color warning_color
	local contrast1 contrast2 contrast3
	local blend1 blend2

	P_DIR_MODE="full"

	P_SHOW_DIR="$("$sm" -g .ui.dir.show -n 2>/dev/null || printf '1')"
	P_DIR_SHORTEN_ACTIVE="$("$sm" -g .ui.dir.shorten -n 2>/dev/null || printf '1')"
	P_DIR_MAX_RATIO="$("$sm" -g .ui.dir.max_ratio 2>/dev/null || printf '60')"

	P_SHOW_GIT="$("$sm" -g .ui.git.show -n 2>/dev/null || printf '1')"
	
	P_SHOW_HOSTNAME="$("$sm" -g .ui.hostname.show -n 2>/dev/null || printf '0')"
	P_HOSTNAME_POS="$("$sm" -g .ui.hostname.side -n 2>/dev/null || printf '0')" 

	P_SHOW_TIME="$("$sm" -g .ui.time.show -n 2>/dev/null || printf '0')"
	P_TIME_POS="$("$sm" -g .ui.time.side -n 2>/dev/null || printf '1')"

	success_color="$("$sm" -g .theme.success 2>/dev/null || printf '#00ff00')"
	error_color="$("$sm" -g .theme.error 2>/dev/null || printf '#ff0000')"
	warning_color="$("$sm" -g .theme.warning 2>/dev/null || printf '#ffff00')"

	contrast1="$("$sm" -g .theme.contrast1 2>/dev/null || printf '#ff00ff')"
	contrast2="$("$sm" -g .theme.contrast2 2>/dev/null || printf '#00ffff')"
	contrast3="$("$sm" -g .theme.contrast3 2>/dev/null || printf '#ffffff')"

	blend1="$("$sm" -g .theme.blend1 2>/dev/null || printf '#ff5555')"
	blend2="$("$sm" -g .theme.blend2 2>/dev/null || printf '#55ff55')"

	P_SUCCESS="%F{$success_color}"
	P_ERROR="%F{$error_color}"
	P_WARNING="%F{$warning_color}"

	P_HILIGHT1="%F{$contrast1}"
	P_HILIGHT2="%F{$contrast2}"
	P_HILIGHT3="%F{$contrast3}"

	P_BLEND1="%F{$blend1}"
	P_BLEND2="%F{$blend2}"

	P_RESET="%f"
}

load_prompt_env
