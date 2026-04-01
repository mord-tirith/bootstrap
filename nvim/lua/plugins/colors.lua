local state = require("config.theme_state")

local plugins = {}

for _, theme in ipairs(state.themes) do
	table.insert(plugins, { theme.plugin })
end

return plugins
