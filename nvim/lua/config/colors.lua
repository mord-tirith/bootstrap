local M = {}

local state = require("config.theme_state")

local function state_file_path()
	return vim.fn.stdpath("config") .. "/lua/config/theme_state.lua"
end

local function save_state()
	local path = state_file_path()
	local file = io.open(path, "w")

	if not file then
		vim.notify("Failed to save theme state", vim.log.levels.ERROR)
		return
	end

	file:write("return {\n")
	file:write(string.format('\tcurrent = "%s",\n', state.current))
	file:write("\tthemes = {\n")

	for _, theme in ipairs(state.themes) do
		file:write("\t\t{\n")
		file:write(string.format('\t\t\tname = "%s",\n', theme.name))
		file:write(string.format('\t\t\tplugin = "%s",\n', theme.plugin))
		file:write("\t\t},\n")
	end

	file:write("\t},\n")
	file:write("}\n")
	file:close()
end

local function get_theme_names()
	local names = {}
	for _, theme in ipairs(state.themes) do
		table.insert(names, theme.name)
	end
	return names
end

function M.apply(name)
	local ok, theme = pcall(require, "themes." .. name)

	if not ok then
		vim.notify("Theme not found: " .. name, vim.log.levels.ERROR)
		return
	end

	theme()
	state.current = name
	save_state()
	vim.notify("Theme changed to " .. name, vim.log.levels.INFO)
end

function M.load_current()
	local ok, theme = pcall(require, "themes." .. state.current)

	if ok then
		theme()
	else
		vim.notify("Failed to load theme: " .. state.current, vim.log.levels.ERROR)
	end
end

function M.show_current()
	print("Current theme: " .. state.current)
end

function M.pick_theme()
	vim.ui.select(state.themes, {
		prompt = "Choose a theme",
		format_item = function(item)
			local author = item.plugin:match("([^/]+)/") or "unknown"
			return string.format("%-14s by %s", item.name, author)
		end,
	}, function(choice)
		if choice then
			M.apply(choice.name)
		end
	end)
end

vim.api.nvim_create_user_command("Theme", function(opts)
	M.apply(opts.args)
end, {
	nargs = 1,
	complete = function()
		return get_theme_names()
	end,
})

return M
