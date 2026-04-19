PROMPT_STATE_MANAGER="$HOME/.dotfiles/scripts/state_manager.sh"

load_prompt_env() {
	local sm="$PROMPT_STATE_MANAGER"
	local host_color git_color dir_color time_color arrow_color success_color error_color warn_color

	host_color="$("$sm" --resolve-role hostname 2>/dev/null || printf '#ffff00')"
	git_color="$("$sm" --resolve-role git 2>/dev/null || printf '#ff5555')"
	dir_color="$("$sm" --resolve-role dir 2>/dev/null || printf '#00ffff')"
	time_color="$("$sm" --resolve-role time 2>/dev/null || printf '#ff00ff')"
	arrow_color="$("$sm" --resolve-role arrow 2>/dev/null || printf '#00ff00')"
	success_color="$("$sm" -g .theme.palette.success 2>/dev/null || printf '#00ff00')"
	error_color="$("$sm" -g .theme.palette.error 2>/dev/null || printf '#ff0000')"
	warn_color="$("$sm" -g .theme.palette.warning 2>/dev/null || printf '#ffff00')"

	P_DIR_MODE="full"

	P_SHOW_DIR="$("$sm" -g .ui.dir.show -n 2>/dev/null || printf '1')"
	P_DIR_SHORTEN_ACTIVE="$("$sm" -g .ui.dir.shorten -n 2>/dev/null || printf '1')"
	P_DIR_MAX_RATIO="$("$sm" -g .ui.dir.max_ratio 2>/dev/null || printf '60')"

	P_SHOW_GIT="$("$sm" -g .ui.git.show -n 2>/dev/null || printf '1')"
	
	P_SHOW_HOSTNAME="$("$sm" -g .ui.hostname.show -n 2>/dev/null || printf '0')"
	P_HOSTNAME_POS="$("$sm" -g .ui.hostname.side -n 2>/dev/null || printf '0')" 

	P_SHOW_TIME="$("$sm" -g .ui.time.show -n 2>/dev/null || printf '0')"
	P_TIME_POS="$("$sm" -g .ui.time.side -n 2>/dev/null || printf '1')"

	P_ARROW_STATUS="$("$sm" -g .ui.arrow.status -n 2>/dev/null || printf '1')"

	P_HOST_COLOR="%F{$host_color}"
	P_GIT_COLOR="%F{$git_color}"
	P_DIR_COLOR="%F{$dir_color}"
	P_TIME_COLOR="%F{$time_color}"
	P_ARROW_COLOR="%F{$arrow_color}"
	P_SUCCESS="%F{$success_color}"
	P_ERROR="%F{$error_color}"
	P_WARNING="%F{$warn_color}"
	P_RESET="%f"
}

load_prompt_env
