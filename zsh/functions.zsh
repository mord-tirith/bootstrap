
prompt() {
	~/.local/bin/prompt_manager
	load_prompt_env
	update_prompt_layout
	build_prompt "$?"

	if zle; then
		zle reset-prompt
	fi
}
