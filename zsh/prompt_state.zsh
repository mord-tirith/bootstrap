PROMPT_STATE_MANAGER="$HOME/.dotfiles/scripts/state_manager.sh"

load_prompt_env() {
	local sm="$PROMPT_STATE_MANAGER"
	local success_color error_color warning_color
	local contrast1 contrast2 contrast3
	local blend1 blend2

	export P_SHOW_GIT="$("$sm" -g .ui.show_git -n 2>/dev/null || printf '1')"
	
	export P_SHOW_HOSTNAME="$("$sm" -g .ui.hostname.show -n 2>/dev/null || printf '0')"
	export P_HOSTNAME_POS="$("$sm" -g .ui.hostname.side -n 2>/dev/null || printf 'left')" 

	export P_SHOW_TIME="$("$sm" -g .ui.time.show -n 2>/dev/null || printf '0')"
	export P_TIME_POS="$("$sm" -g .ui.time.side -n 2>/dev/null || printf 'right')"

	success_color="$("$sm" -g .theme.success 2>/dev/null || printf '#00ff00')"
	error_color="$("$sm" -g .theme.error 2>/dev/null || printf '#ff0000')"
	warning_color="$("$sm" -g .theme.warning 2>/dev/null || printf '#ffff00')"

	contrast1="$("$sm" -g .theme.contrast1 2>/dev/null || printf '#ff00ff')"
	contrast2="$("$sm" -g .theme.contrast2 2>/dev/null || printf '#00ffff')"
	contrast3="$("$sm" -g .theme.contrast3 2>/dev/null || printf '#ffffff')"

	blend1="$("$sm" -g .theme.blend1 2>/dev/null || printf '#ff5555')"
	blend2="$("$sm" -g .theme.blend2 2>/dev/null || printf '#55ff55')"

	export P_SUCCESS="%F{$success_color}"
	export P_ERROR="%F{$error_color}"
	export P_WARNING="%F{$warning_color}"

	export P_HILIGHT1="%F{$contrast1}"
	export P_HILIGHT2="%F{$contrast2}"
	export P_HILIGHT3="%F{$contrast3}"

	export P_BLEND1="%F{$blend1}"
	export P_BLEND2="%F{$blend2}"

	export P_RESET="%f"
}

load_prompt_env
